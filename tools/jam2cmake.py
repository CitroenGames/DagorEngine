#!/usr/bin/env python3

import os
import re
import sys
from typing import List, Dict, Set, Optional

class JamToCMakeConverter:
    def __init__(self, root_dir: str):
        self.root_dir = root_dir
        self.variables: Dict[str, str] = {}
        self.sources: List[str] = []
        self.includes: List[str] = []
        self.prog_libs: List[str] = []
        self.platform_sources: Dict[str, List[str]] = {
            "windows": [],
            "unix": []
        }
        self.compiler_flags: Dict[str, List[str]] = {
            "gcc": [],
            "clang": [],
            "msvc": []
        }

    def parse_variable(self, line: str) -> None:
        """Parse Jam variable assignment."""
        # Parse all variable assignments in content
        assignments = re.finditer(
            r'^\s*(\w+)\s*(\?)?=\s*([^;]*);',
            line,
            re.MULTILINE
        )
        for match in assignments:
            var_name = match.group(1).strip()
            value = match.group(3).strip().strip('"')
            self.variables[var_name] = value

    def parse_variables(self, content: str) -> None:
        """Parse all variables in file content."""
        for line in content.split('\n'):
            if '=' in line and ';' in line:
                self.parse_variable(line)

    def parse_sources(self, content: str) -> None:
        """Parse Sources block from Jam file."""
        sources_match = re.search(r'Sources\s*=([^;]*);', content, re.DOTALL)
        if sources_match:
            sources_block = sources_match.group(1)
            self.sources = [
                s.strip().rstrip(' ;')
                for s in sources_block.split('\n')
                if s.strip() and not s.strip().startswith('#')
            ]

    def parse_includes(self, content: str) -> None:
        """Parse AddIncludes block from Jam file."""
        includes_match = re.search(r'AddIncludes\s*=([^;]*);', content, re.DOTALL)
        if includes_match:
            includes_block = includes_match.group(1)
            self.includes = [
                s.strip().rstrip(' ;')
                for s in includes_block.split('\n')
                if s.strip() and not s.strip().startswith('#')
            ]

    def parse_prog_libs(self, content: str) -> None:
        """Parse UseProgLibs block from Jam file."""
        # Parse main UseProgLibs block
        libs_match = re.search(r'UseProgLibs\s*=([^;]*);', content, re.DOTALL)
        if libs_match:
            libs_block = libs_match.group(1)
            self.prog_libs = [
                s.strip().rstrip(' ;')
                for s in libs_block.split('\n')
                if s.strip() and not s.strip().startswith('#')
            ]

        # Parse conditional dependencies
        conditional_blocks = re.finditer(
            r'if\s*([^{]+)\s*{([^}]+)}', content, re.DOTALL
        )

        for block in conditional_blocks:
            condition = block.group(1).strip()
            block_content = block.group(2)

            for line in block_content.split('\n'):
                if 'UseProgLibs' in line and '+=' in line:
                    lib = line.split('+=')[1].strip().rstrip(' ;')
                    if lib:
                        # Convert Jam condition to CMake condition
                        cmake_condition = condition.replace(
                            '$(Platform)', '${DAGOR_PLATFORM}'
                        ).replace('=', ' STREQUAL ')

                        # Add conditional library
                        self.prog_libs.append(f'$<$<BOOL:{cmake_condition}>:{lib}>')

    def parse_platform_sources(self, content: str) -> None:
        """Parse platform-specific source files."""
        # Windows sources
        win_patterns = [
            r'if\s*\$\(Platform\)\s*=\s*windows\s*{([^}]*)}',
            r'if\s*\$\(Platform\)\s*==\s*windows\s*{([^}]*)}',
            r'if\s*windows\s*=\s*\$\(Platform\)\s*{([^}]*)}'
        ]

        for pattern in win_patterns:
            win_match = re.search(pattern, content, re.DOTALL)
            if win_match:
                win_block = win_match.group(1)
                for line in win_block.split('\n'):
                    if 'Sources' in line and '.cpp' in line:
                        parts = line.split('+=')
                        if len(parts) > 1:
                            file = parts[1].strip().rstrip(' ;')
                            if file not in self.platform_sources["windows"]:
                                self.platform_sources["windows"].append(file)

        # Unix (macOS/Linux) sources
        unix_patterns = [
            r'if\s*\$\(Platform\)\s*in\s*macOS\s*linux\s*{([^}]*)}',
            r'if\s*\$\(Platform\)\s*in\s*\[\s*macOS\s*linux\s*\]\s*{([^}]*)}',
            r'if\s*\[\s*macOS\s*linux\s*\]\s*in\s*\$\(Platform\)\s*{([^}]*)}'
        ]

        for pattern in unix_patterns:
            unix_match = re.search(pattern, content, re.DOTALL)
            if unix_match:
                unix_block = unix_match.group(1)
                for line in unix_block.split('\n'):
                    if 'Sources' in line and '.cpp' in line:
                        parts = line.split('+=')
                        if len(parts) > 1:
                            file = parts[1].strip().rstrip(' ;')
                            if file not in self.platform_sources["unix"]:
                                self.platform_sources["unix"].append(file)

    def parse_compiler_flags(self, content: str) -> None:
        """Parse compiler flags from *-sets.jam files."""
        gcc_match = re.search(r'_DEF_COM_CMDLINE\s*=([^;]*);', content, re.DOTALL)
        if gcc_match:
            flags = gcc_match.group(1).strip().split('\n')
            self.compiler_flags["gcc"] = [
                f.strip()
                for f in flags
                if f.strip() and not f.strip().startswith('#')
            ]

        clang_match = re.search(r'if\s*\$\(PlatformSpec\)\s*=\s*clang\s*{([^}]*)}', content)
        if clang_match:
            flags = clang_match.group(1).strip().split('\n')
            self.compiler_flags["clang"] = [
                f.strip().split('+=')[1].strip().rstrip(';')
                for f in flags
                if '+=' in f and not f.strip().startswith('#')
            ]

    def format_path(self, path: str) -> str:
        """Format Jam path to CMake path."""
        if path.startswith('$(Root)'):
            return path.replace('$(Root)', '${CMAKE_SOURCE_DIR}')
        return path

    def generate_cmake(self, target_name: str) -> str:
        """Generate CMake content from parsed Jam file."""
        cmake_content = []
        cmake_content.append("# Generated from Jam files")
        cmake_content.append("cmake_minimum_required(VERSION 3.20)")
        cmake_content.append("")

        target_type = self.variables.get("TargetType", "exe")
        is_console = self.variables.get("ConsoleExe", "no") == "yes"

        sources_str = '\n        '.join(self.sources)
        win_sources_str = '\n        '.join(self.platform_sources["windows"])
        unix_sources_str = '\n        '.join(self.platform_sources["unix"])

        includes_str = '\n        '.join(self.format_path(inc) for inc in self.includes)

        libs_str = '\n        '.join(self.prog_libs)

        if self.compiler_flags["gcc"] or self.compiler_flags["clang"]:
            cmake_content.append("# Compiler flags")
            if self.compiler_flags["gcc"]:
                cmake_content.append("if(CMAKE_COMPILER_IS_GNUCXX)")
                for flag in self.compiler_flags["gcc"]:
                    cmake_content.append(f'    add_compile_options({flag})')
                cmake_content.append("endif()")
            if self.compiler_flags["clang"]:
                cmake_content.append("if(CMAKE_CXX_COMPILER_ID MATCHES \"Clang\")")
                for flag in self.compiler_flags["clang"]:
                    cmake_content.append(f'    add_compile_options({flag})')
                cmake_content.append("endif()")
            cmake_content.append("")

        if target_type == "exe":
            cmake_content.append(f"""dagor_add_executable(
    NAME {target_name}
    CONSOLE {'TRUE' if is_console else 'FALSE'}
    SOURCES
        {sources_str}
    WIN_SOURCES
        {win_sources_str}
    UNIX_SOURCES
        {unix_sources_str}
    INCLUDES
        {includes_str}
    USE_PROG_LIBS
        {libs_str}
)""")
        else:
            cmake_content.append(f"""dagor_add_library(
    NAME {target_name}
    {'SHARED' if target_type == 'dll' else 'STATIC'}
    SOURCES
        {sources_str}
    WIN_SOURCES
        {win_sources_str}
    UNIX_SOURCES
        {unix_sources_str}
    INCLUDES
        {includes_str}
    USE_PROG_LIBS
        {libs_str}
)""")

        return '\n'.join(cmake_content)

    def convert_file(self, jam_file: str) -> Optional[str]:
        """Convert a Jam file to CMake format."""
        try:
            with open(jam_file, 'r') as f:
                content = f.read()

            # Parse all variables first
            self.parse_variables(content)

            # Parse other sections
            self.parse_sources(content)
            self.parse_includes(content)
            self.parse_prog_libs(content)
            self.parse_platform_sources(content)
            self.parse_compiler_flags(content)

            # Generate target name from directory
            target_dir = os.path.dirname(jam_file)
            target_name = os.path.basename(target_dir)

            return self.generate_cmake(target_name)
        except Exception as e:
            print(f"Error converting {jam_file}: {str(e)}", file=sys.stderr)
            return None

def main():
    if len(sys.argv) != 2:
        print("Usage: jam2cmake.py <jam_file>")
        sys.exit(1)

    jam_file = sys.argv[1]
    if not os.path.exists(jam_file):
        print(f"Error: File {jam_file} not found", file=sys.stderr)
        sys.exit(1)

    converter = JamToCMakeConverter(os.path.dirname(os.path.dirname(jam_file)))
    cmake_content = converter.convert_file(jam_file)

    if cmake_content:
        output_dir = os.path.dirname(jam_file)
        output_file = os.path.join(output_dir, "CMakeLists.txt")

        with open(output_file, 'w') as f:
            f.write(cmake_content)
        print(f"Successfully converted {jam_file} to {output_file}")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
