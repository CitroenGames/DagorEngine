// Copyright (C) Gaijin Games KFT.  All rights reserved.

#include <atomic>
#include <EASTL/vector_set.h>
#include <EASTL/fixed_string.h>
#include <EASTL/fixed_vector.h>
#include <fmod_studio.hpp>
#include <ioSys/dag_dataBlock.h>
#include <osApiWrappers/dag_critSec.h>
#include <soundSystem/soundSystem.h>
#include <soundSystem/fmodApi.h>
#include <soundSystem/debug.h>
#include <soundSystem/vars.h>
#include <soundSystem/varId.h>
#include <soundSystem/geometry.h>
#include "internal/events.h"
#include "internal/fmodCompatibility.h"
#include "internal/occlusion.h"
#include "internal/debug.h"

static WinCritSec g_occlusion_cs;
#define SNDSYS_OCCLUSION_BLOCK WinAutoLock occlusionLock(g_occlusion_cs);

namespace sndsys::occlusion
{
using fmod_instance_t = FMOD::Studio::EventInstance;

static constexpr size_t g_sources_capacity = 64;
static constexpr group_id_t g_invalid_group_id = {};
static constexpr float g_uninited_value = -1;
static constexpr float g_default_value = 0;

static eastl::fixed_string<char, 32, true> g_occlusion_param_name;
static float g_near_attenuation = 0.f;
static float g_far_attenuation = 0.f;
static Point3 g_listener_pos = {};
static std::atomic_bool g_occlusion_inited = ATOMIC_VAR_INIT(false);

struct Source
{
  fmod_instance_t *instance = nullptr;
  group_id_t groupId = g_invalid_group_id;
  Point3 pos = {};
  VarId varId = {};
  float value = g_uninited_value;

  bool operator==(const Source &other) const { return instance == other.instance && groupId == other.groupId; }
  bool operator!=(const Source &other) const { return instance != other.instance || groupId != other.groupId; }
  bool operator<(const Source &other) const
  {
    return (groupId != other.groupId) ? (groupId < other.groupId) : (intptr_t(instance) < intptr_t(other.instance));
  }
};

/* legend:
 *
 * inst  invalid_group_id  pos  tIdx=0
 * inst  invalid_group_id  pos  tIdx=1
 * inst  invalid_group_id  pos  tIdx=2
 * inst  invalid_group_id  pos  tIdx=3
 *
 * inst  grp0  pos  tIdx=4
 * inst  grp0  ^    ^
 * inst  grp0  ^    ^
 *
 * inst  grp1  pos  tIdx=5
 * inst  grp1  ^    ^
 *
 * inst  grp2  pos  tIdx=6
 * inst  grp2  ^    ^
 * inst  grp2  ^    ^
 * inst  grp2  ^    ^
 */

static eastl::vector_set<Source, eastl::less<Source>, EASTLAllocatorType,
  eastl::fixed_vector<Source, g_sources_capacity, /*overflow*/ true>>
  g_sources;

struct FindAsGroupId : public eastl::binary_function<group_id_t, Source, bool>
{
  bool operator()(group_id_t a, const Source &b) const { return a < b.groupId; }
  bool operator()(const Source &a, group_id_t b) const { return a.groupId < b; }
};

static Source *find_first_source_in_group(group_id_t group_id)
{
  auto fnd = g_sources.find_as(group_id, FindAsGroupId());
  if (fnd == g_sources.end())
    return nullptr;
  for (; fnd > g_sources.begin() && fnd[-1].groupId == fnd->groupId; --fnd) {}
  G_ASSERT(fnd->groupId == group_id);
  return fnd;
}

static Source *find_source_by_instance_no_group(fmod_instance_t *instance)
{
  auto fnd = g_sources.find(Source{instance, g_invalid_group_id});
  if (fnd == g_sources.end())
    return nullptr;
  G_ASSERT(instance == fnd->instance && fnd->groupId == g_invalid_group_id);
  return fnd;
}

static Source *find_source_by_instance_only(fmod_instance_t *instance)
{
  for (Source &src : g_sources)
    if (src.instance == instance)
      return &src;
  return nullptr;
}

static Source *get_next_source_in_group(Source *src)
{
  G_ASSERT(src >= g_sources.begin() && src < g_sources.end());
  if (src->groupId != g_invalid_group_id)
  {
    Source *next = src + 1;
    if (next < g_sources.end() && next->groupId == src->groupId)
      return next;
  }
  return nullptr;
}

static bool is_in_group(Source &src) { return src.groupId != g_invalid_group_id; }

static bool is_first_in_group(Source &src)
{
  if (!is_in_group(src))
    return false;
  return (&src > g_sources.begin()) ? (&src - 1)->groupId != src.groupId : &src == g_sources.begin();
}

static void insert(const Source &value)
{
  const auto ins = g_sources.insert(value);
  Source *src = ins.first;
  G_ASSERT(ins.second && src >= g_sources.begin() && src < g_sources.end());
  if (Source *next = get_next_source_in_group(src))
    src->pos = next->pos;
}

static void erase(Source *src)
{
  G_ASSERT(src >= g_sources.begin() && src < g_sources.end());
  if (Source *next = get_next_source_in_group(src))
    next->pos = src->pos;
  g_sources.erase(src);
}

void append(FMOD::Studio::EventInstance *instance, const FMOD::Studio::EventDescription *description_, const Point3 &pos)
{
  TIME_PROFILE_DEV(sndsys_occlusion_append);
  if (!g_occlusion_inited)
    return;
  SNDSYS_OCCLUSION_BLOCK;

  FMOD_STUDIO_PARAMETER_DESCRIPTION desc;
  SOUND_VERIFY(description_->getParameterDescriptionByName(g_occlusion_param_name.c_str(), &desc));
  const VarId varId = as_var_id(desc.id);
  if (varId)
    insert(Source{instance, g_invalid_group_id, pos, varId});
  else
    logerr("missing var labeled '%s' in event '%s'", g_occlusion_param_name.c_str(), get_debug_name(*description_).c_str());
}

void set_pos(FMOD::Studio::EventInstance &instance, const Point3 &pos)
{
  if (!g_occlusion_inited)
    return;
  SNDSYS_OCCLUSION_BLOCK;

  if (Source *src = find_source_by_instance_no_group(&instance))
    src->pos = pos;
}

void set_pos(group_id_t group_id, const Point3 &pos)
{
  if (!g_occlusion_inited)
    return;
  SNDSYS_OCCLUSION_BLOCK;

  if (Source *src = find_first_source_in_group(group_id))
    src->pos = pos;
}

void set_group(FMOD::Studio::EventInstance *instance, group_id_t group_id)
{
  if (!g_occlusion_inited)
    return;
  SNDSYS_OCCLUSION_BLOCK;

  Source *src = find_source_by_instance_only(instance);
  if (!src)
    return;

  Source cpy = *src;

  cpy.groupId = group_id;

  erase(src);

  insert(cpy);
}

static float make_occlusion_impl(const Point3 &pos, FMOD::System &low_level_system)
{
  TIME_PROFILE_DEV(sndsys_occlusion_make_occlusion);

  float value = 0.;

  const Point3 dir = pos - g_listener_pos;

  if (dir.lengthSq() < sqr(g_far_attenuation))
  {
    SOUND_VERIFY(low_level_system.getGeometryOcclusion(&as_fmod_vector(pos), &as_fmod_vector(g_listener_pos), &value, nullptr));

    value = cvt(dir.length(), g_near_attenuation, g_far_attenuation, value, 0.f);

    value = saturate(value);
  }

  return value;
}

static void set_occlusion(Source &src, float value)
{
  if (src.value != value)
  {
    src.value = value;
    SOUND_VERIFY(src.instance->setParameterByID(as_fmod_param_id(src.varId), value));
  }
}

void apply_oneshot(FMOD::Studio::EventInstance &instance, const Point3 &pos, FMOD::System &low_level_system)
{
  TIME_PROFILE_DEV(sndsys_occlusion_apply_oneshot);
  if (!g_occlusion_inited)
    return;
  SNDSYS_OCCLUSION_BLOCK;

  if (!g_listener_pos.lengthSq())
    return;

  const float value = make_occlusion_impl(pos, low_level_system);

  if (value != g_default_value)
    SOUND_VERIFY(instance.setParameterByName(g_occlusion_param_name.c_str(), value));
}

void erase(FMOD::Studio::EventInstance *instance, bool apply_occlusion)
{
  if (!g_occlusion_inited)
    return;
  SNDSYS_OCCLUSION_BLOCK;
  if (Source *src = find_source_by_instance_only(instance))
  {
    if (apply_occlusion)
      if (src->value == g_uninited_value)
        if (src->groupId == g_invalid_group_id)
          if (src->instance->isValid())
            if (auto sys = fmodapi::get_system())
            {
              // instance was created, and then was abandoned, but it still playing
              set_occlusion(*src, make_occlusion_impl(src->pos, *sys));
            }
    erase(src);
  }
}

static intptr_t g_cur_offset = 0;

void update(const Point3 &listener, FMOD::System &low_level_system)
{
  TIME_PROFILE_DEV(sndsys_occlusion_update);
  if (!g_occlusion_inited)
    return;
  SNDSYS_OCCLUSION_BLOCK;
  g_listener_pos = listener;
  if (!g_listener_pos.lengthSq())
    return;

  if (g_sources.empty())
  {
    g_cur_offset = 0;
    return;
  }

  intptr_t tIdx = -1;
  constexpr intptr_t traces = 4;

  g_cur_offset %= g_sources.size();
  const intptr_t a = g_cur_offset;
  const intptr_t b = g_cur_offset + traces;
  g_cur_offset += traces;

  float value = 0.f;

  for (intptr_t i = 0; i < g_sources.size();)
  {
    Source &src = g_sources[i];

    if (!src.instance->isValid())
    {
      erase(&src);
      if (g_cur_offset >= g_sources.size())
        g_cur_offset -= g_sources.size();
      continue;
    }

    if (is_first_in_group(src) || !is_in_group(src))
    {
      ++tIdx;

      if (src.value == g_uninited_value || ((tIdx >= a && tIdx < b) || (tIdx + g_sources.size() >= a && tIdx + g_sources.size() < b)))
        set_occlusion(src, make_occlusion_impl(src.pos, low_level_system));

      value = src.value;
    }

    set_occlusion(src, value);

    ++i;
  }
}

void debug_enum_sources(debug_enum_sources_t debug_enum_sources)
{
  if (!g_occlusion_inited)
    return;
  for (Source &src : g_sources)
    debug_enum_sources(src.instance, src.groupId, src.pos, src.value, is_in_group(src), is_first_in_group(src));
}

void set_group_pos(group_id_t group_id, const Point3 &pos)
{
  if (!g_occlusion_inited)
    return;
  set_pos(group_id, pos);
}

void set_event_group(EventHandle event_handle, group_id_t group_id)
{
  if (!g_occlusion_inited)
    return;
  if (fmod_instance_t *instance = fmodapi::get_instance(event_handle))
    set_group(instance, group_id);
}

bool is_inited() { return g_occlusion_inited; }

void init(const DataBlock &blk)
{
  SNDSYS_OCCLUSION_BLOCK;

  G_ASSERT(!g_occlusion_inited);
  g_occlusion_inited = false;
  g_occlusion_param_name = blk.getStr("occlusionParamName", "occlusion");
  G_ASSERT_RETURN(!g_occlusion_param_name.empty(), );

  g_near_attenuation = blk.getReal("occlusionNearAttenuation", 40.f);
  g_far_attenuation = blk.getReal("occlusionFarAttenuation", 45.f);

  g_occlusion_inited = true;
}

} // namespace sndsys::occlusion
