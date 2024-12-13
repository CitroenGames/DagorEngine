#!/usr/bin/env python3
# module to help building DagorEngine code, shaders and game data using CMake
import sys
import subprocess
import pathlib
import os
import platform
import multiprocessing
import argparse
from typing import List, Optional, Dict

DAGOR_ROOT_FOLDER = os.path.dirname(os.path.realpath(__file__))
DAGOR_HOST_ARCH = 'x86_64'

# Platform detection
if sys.platform.startswith('win'):
    DAGOR_HOST = 'windows'
    DAGOR_TOOLS_FOLDER = os.path.realpath('{0}/tools/dagor_cdk/windows-{1}'.format(DAGOR_ROOT_FOLDER, DAGOR_HOST_ARCH))
elif sys.platform.startswith('darwin'):
    DAGOR_HOST = 'macOS'
    DAGOR_TOOLS_FOLDER = os.path.realpath('{0}/tools/dagor_cdk/macOS-{1}'.format(DAGOR_ROOT_FOLDER, DAGOR_HOST_ARCH))
elif sys.platform.startswith('linux'):
    DAGOR_HOST = 'linux'
    DAGOR_HOST_ARCH = platform.uname().machine
    DAGOR_TOOLS_FOLDER = os.path.realpath('{0}/tools/dagor_cdk/linux-{1}'.format(DAGOR_ROOT_FOLDER, DAGOR_HOST_ARCH))
else:
    print('\nERROR: unsupported platform {0}\n'.format(sys.platform))
    exit(1)

# Tool paths (maintaining compatibility with build_all.py)
VROMFS_PACKER_EXE = os.path.realpath('{0}/vromfsPacker-dev{1}'.format(DAGOR_TOOLS_FOLDER, '.exe' if DAGOR_HOST == 'windows' else ''))
DABUILD_EXE = os.path.realpath('{0}/daBuild-dev{1}'.format(DAGOR_TOOLS_FOLDER, '.exe' if DAGOR_HOST == 'windows' else ''))
DABUILD_CMD = [DABUILD_EXE, '-jobs:{}'.format(multiprocessing.cpu_count()), '-q']
FONTGEN_EXE = os.path.realpath('{0}/fontgen2-dev{1}'.format(DAGOR_TOOLS_FOLDER, '.exe' if DAGOR_HOST == 'windows' else ''))

def log_info(message: str) -> None:
    """Log information message."""
    print(f"\033[94m[INFO]\033[0m {message}")

def log_warning(message: str) -> None:
    """Log warning message."""
    print(f"\033[93m[WARNING]\033[0m {message}")

def log_error(message: str) -> None:
    """Log error message."""
    print(f"\033[91m[ERROR]\033[0m {message}")

def run(cmd: List[str], cwd: Optional[str] = None, env: Optional[Dict[str, str]] = None) -> bool:
    """Run a command and handle errors."""
    try:
        log_info(f"Running command: {' '.join(cmd)}")
        result = subprocess.run(cmd, cwd=cwd, env=env, check=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                universal_newlines=True)
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"Command failed with exit code {e.returncode}")
        if e.stdout:
            print(e.stdout)
        if e.stderr:
            print(e.stderr)
        return False
    except Exception as e:
        log_error(f"Failed to run command: {e}")
        return False

def run_per_platform(cmds_windows=[], cmds_macOS=[], cmds_linux=[], cwd='.', env=None) -> bool:
    """Run platform-specific commands."""
    cmds = []
    if DAGOR_HOST == 'windows':
        cmds = cmds_windows
    elif DAGOR_HOST == 'macOS':
        cmds = cmds_macOS
    elif DAGOR_HOST == 'linux':
        cmds = cmds_linux

    for cmd in cmds:
        if not run(cmd, cwd=cwd, env=env):
            return False
    return True

def configure_cmake(build_dir: str, source_dir: str, options: List[str]) -> bool:
    """Configure CMake build."""
    os.makedirs(build_dir, exist_ok=True)

    # Set up CMake module paths
    cmake_module_path = os.path.join(DAGOR_ROOT_FOLDER, 'cmake', 'Modules')
    cmake_platform_path = os.path.join(DAGOR_ROOT_FOLDER, 'cmake', 'Platform')

    # Combine module paths
    combined_module_path = f"{cmake_module_path};{cmake_platform_path}"

    # Base CMake command
    cmake_cmd = [
        'cmake',
        '-B', build_dir,
        '-S', source_dir,
        f'-DCMAKE_MODULE_PATH={combined_module_path}',
        '-G', 'Ninja'
    ]

    # Add additional options
    cmake_cmd.extend(options)

    log_info(f"--- Running: {cmake_cmd} in {os.getcwd()}")
    return run(cmake_cmd, cwd='.')

def build_cmake(build_dir: str, config: str = 'Release') -> bool:
    """Build using CMake."""
    log_info(f"Building in {build_dir} with config {config}")
    return run(['cmake', '--build', build_dir, '--config', config, '--parallel', str(multiprocessing.cpu_count())])

def compile_shaders(project_dir: str, shader_dir: str) -> bool:
    """Compile shaders for the current platform."""
    shader_dir = os.path.join(project_dir, shader_dir)
    if not os.path.exists(shader_dir):
        log_info(f"Shader directory {shader_dir} not found, skipping shader compilation")
        return True

    return run_per_platform(
        cmds_windows=['compile_shaders_dx12.bat', 'compile_shaders_dx11.bat', 'compile_shaders_metal.bat', 'compile_shaders_spirv.bat'],
        cmds_macOS=['./compile_shaders_metal.sh'],
        cmds_linux=['./compile_shaders_spirv.sh'],
        cwd=shader_dir
    )

def build_project(project: str, components: List[str], build_dir: str, args: argparse.Namespace) -> bool:
    """Build a specific project."""
    # Map project names to their directories
    project_paths = {
        'ShaderCompiler2': 'prog/tools/ShaderCompiler2',
        'dagorTools': 'prog/tools',
        'dargbox': 'prog/tools/dargbox',
        'physTest': 'samples/physTest/prog',
        'skiesSample': 'samples/skiesSample/prog',
        'testGI': 'samples/testGI/prog',
        'outerSpace': 'outerSpace/prog',
        'dngSceneViewer': 'samples/dngSceneViewer/prog'
    }

    if project not in project_paths:
        log_error(f'Unknown project: {project}')
        return False

    project_dir = os.path.join(DAGOR_ROOT_FOLDER, project_paths[project])

    # Convert Jam files to CMake if needed
    jam2cmake = os.path.join(DAGOR_ROOT_FOLDER, 'tools', 'jam2cmake.py')
    if os.path.exists(jam2cmake):
        for root, _, files in os.walk(project_dir):
            for file in files:
                if file.endswith('.jam'):
                    run([sys.executable, jam2cmake, os.path.join(root, file)])

    # Build code if requested
    if 'code' in components:
        project_build_dir = os.path.join(build_dir, project)
        cmake_options = [
            f'-DCMAKE_BUILD_TYPE=Release',
            f'-DDAGOR_PLATFORM={DAGOR_HOST}',
            f'-DDAGOR_ARCH={DAGOR_HOST_ARCH}'
        ]

        # Only pass sanitizer option if it's explicitly enabled
        if args.sanitize and args.sanitize not in ['disabled', '']:
            cmake_options.append(f'-DDAGOR_SANITIZE={args.sanitize}')
        else:
            cmake_options.append('-DDAGOR_SANITIZE=disabled')

        if not configure_cmake(project_build_dir, project_dir, cmake_options):
            return False
        if not build_cmake(project_build_dir):
            return False

    # Build shaders if requested
    if 'shaders' in components:
        if not compile_shaders(project_dir, 'shaders'):
            return False

    # Build assets if requested
    if 'assets' in components:
        assets_dir = os.path.join(project_dir, '..', 'develop')
        if os.path.exists(assets_dir):
            if not run(DABUILD_CMD + ['application.blk'], cwd=assets_dir):
                return False

    # Build vromfs if requested
    if 'vromfs' in components:
        vromfs_dir = os.path.join(project_dir, 'vromfs')
        if os.path.exists(vromfs_dir):
            if not run([VROMFS_PACKER_EXE, 'data.vromfs.blk', '-platform:PC', '-quiet'], cwd=vromfs_dir):
                return False

    # Build GUI if requested
    if 'gui' in components:
        gui_dir = os.path.join(project_dir, 'gui')
        if os.path.exists(gui_dir):
            # Check for font generation
            fonts_dir = os.path.join(gui_dir, 'fonts')
            if os.path.exists(fonts_dir):
                if not run([FONTGEN_EXE, '-quiet'], cwd=fonts_dir):
                    return False

            # Build GUI assets
            if os.path.exists(os.path.join(gui_dir, 'application.blk')):
                if not run(DABUILD_CMD + ['application.blk'], cwd=gui_dir):
                    return False

    return True

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Build DagorEngine using CMake')
    parser.add_argument('components', nargs='*', help='Build components (code/shaders/assets/vromfs/gui)')
    parser.add_argument('--project', action='append', dest='projects',
                      help='Projects to build (can be specified multiple times)')
    parser.add_argument('--arch', help='Target architecture')
    parser.add_argument('--sanitize', choices=['disabled', '', 'address', 'thread', 'undefined'],
                      help='Enable sanitizer (disabled, address, thread, undefined)', default='disabled')
    args = parser.parse_args()

    # Set default components if none specified
    components = args.components or ['code', 'shaders', 'assets', 'vromfs', 'gui']

    # Set default projects if none specified
    projects = args.projects or ['dagorTools', 'dargbox', 'physTest', 'skiesSample', 'testGI', 'outerSpace', 'dngSceneViewer']

    # Create build directory
    build_dir = os.path.join(DAGOR_ROOT_FOLDER, 'build')
    os.makedirs(build_dir, exist_ok=True)

    # Build each project
    for project in projects:
        log_info(f'=== Building {project} ===')
        if not build_project(project, components, build_dir, args):
            log_error(f'Failed to build {project}')
            return 1

    log_info('Build completed successfully')
    return 0

if __name__ == '__main__':
    sys.exit(main())
