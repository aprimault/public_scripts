#!/usr/bin/env bash

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <start> <end> <project_name>"
    exit 1
fi

get_all_except_one() {
    local array=("${!1}")
    local index_to_exclude=$2
    local result=()

    for i in "${!array[@]}"; do
        if [[ $i -ne $index_to_exclude ]]; then
            result+=("${array[$i]}")
        fi
    done

    echo "${result[@]}"
}

array_to_string_with_newlines() {
    local array=("$@")
    local result=""

    for element in "${array[@]}"; do
        result+="$element"$'\n'
    done

    echo -n "$result"
}

generate_template() {
    local template_file=$1
    local output_file=$2
    local to_replace=$3
    shift 3
    local names=("$@")

    local template=$(<"$template_file")

    local all_names=$(array_to_string_with_newlines "${names[@]}")
    template="${template//$to_replace/$all_names}"
    template="${template//%%%%%%/ }"

    echo "$template" > "$output_file"
}

MY_FILES=()
ALL_CFG_TARGETS=()
ALL_FCT_DEF=()
ALL_H_DEF=()
ALL_INCLUDES_EX=()
ALL_WORKSPACE_TARGETS=()

mkdir -p "$3"

cd "$3" || exit

git clone https://github.com/aprimault/public_scripts

for i in $(seq $1 $2); do
  formatted=$(printf "%02d" $i)
    MY_FILES+=("exercice$formatted.c")
    ALL_CFG_TARGETS+=("configure_target(exercice$formatted \"\${SOURCE_FILES}\" \"$formatted\")")
    ALL_H_DEF+=("int ex${formatted}_main();")
    ALL_FCT_DEF+=($'\t'"add_function(\"ex${formatted}_main\", ex${formatted}_main);")
    ALL_INCLUDES_EX+=("#include%%%%%%\"exercice$formatted.c\"")
    ALL_WORKSPACE_TARGETS+=("<configuration name=\"exercice$formatted\" type=\"CMakeRunConfiguration\" factoryName=\"Application\" REDIRECT_INPUT=\"false\" ELEVATE=\"false\" USE_EXTERNAL_CONSOLE=\"false\" EMULATE_TERMINAL=\"false\" PASS_PARENT_ENVS_2=\"true\" PROJECT_NAME=\"td_c\" TARGET_NAME=\"exercice$i\" CONFIG_NAME=\"Debug\" RUN_TARGET_PROJECT_NAME=\"td_c\" RUN_TARGET_NAME=\"exercice$formatted\"><method v=\"2\"><option name=\"com.jetbrains.cidr.execution.CidrBuildBeforeRunTaskProvider\$BuildBeforeRunTask\" enabled=\"true\" /></method></configuration>")
done

for i in $(seq $1 $2); do
  formatted=$(printf "%02d" $i)
    all_inc=($(get_all_except_one ALL_INCLUDES_EX[@] $i))
    cp "public_scripts/template_ex.txt" "exercice$formatted.c"
    generate_template "public_scripts/template_ex.txt" "exercice$formatted.c" "{{ALL_INCLUDES}}" "${all_inc[@]}"
    generate_template "exercice$formatted.c" "exercice$formatted.c" "{{EX_NB}}" "$formatted"
done

generate_template "public_scripts/template_main.txt" "main.c" "{{ALL_FCT_DEF}}" "${ALL_FCT_DEF[@]}"
generate_template "public_scripts/template_main_h.txt" "main.h" "{{ALL_H_DEF}}" "${ALL_H_DEF[@]}"
generate_template "main.h" "main.h" "{{ALL_INCLUDES}}" "${ALL_INCLUDES_EX[@]}"
generate_template "public_scripts/template_cmake.txt" "CMakeLists.txt" "{{ALL_CFG_TARGETS}}" "${ALL_CFG_TARGETS[@]}"
generate_template "CMakeLists.txt" "CMakeLists.txt" "{{PROJ_NAME}}" "$3"

rm -rf public_scripts

clion . &


