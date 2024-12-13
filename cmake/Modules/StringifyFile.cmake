# Helper script to stringify shader files
# Used by dagor_stringify_shader_file function

# Read input file
file(READ "${INPUT_FILE}" content)

# Convert to C string format
string(REPLACE "\\" "\\\\" content "${content}")
string(REPLACE "\"" "\\\"" content "${content}")
string(REPLACE "\n" "\\n\"\n\"" content "${content}")

# Write output
file(WRITE "${OUTPUT_FILE}" "\"${content}\"")
