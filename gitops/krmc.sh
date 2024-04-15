#!/bin/bash

set -o errexit

color_red='\033[0;31m'
color_green='\033[0;32m'
color_purple='\033[1;35m'
color_grey='\033[90m'
color_reset='\033[0m'

red() {
  printf "${color_red}$1${color_reset}"
}

green() {
  printf "${color_green}$1${color_reset}"
}

purple() {
  printf "${color_purple}$1${color_reset}"
}

failed() {
  red " [FAILED]\n"
}

ok() {
  green " [OK]\n"
}

debug() {
  if [ "$debug" == "true" ]; then
    printf "${color_grey}[debug] $1${color_reset}\n"
  fi
}

set_exit_code() {
  echo "$1" > /tmp/kubeml_exit_code
}

get_exit_code() {
  cat /tmp/kubeml_exit_code
}

find_kustomization_files() {
  find_command="find \"$1\" -type f \( -name \"kustomization.yaml\" -o -name \"kustomization.yml\" \)"

  if [ ${#ignored_dirs[@]} -eq 0 ]; then
    eval "$find_command"
  else
    local ignore_pattern=""

    for dir in $ignored_dirs; do
      ignore_pattern+="\|$dir"
    done
    eval "$find_command" | grep -v ".*\(${ignore_pattern:2}\).*"
  fi
}

build() {
  local kustomize_flags=(
    "--load-restrictor" $kustomize_load_restrictor
  )

  for file in $(find_kustomization_files "$1"); do
    working_dir=$(dirname "$file")

    kustomize_command="kustomize build $working_dir ${kustomize_flags[*]}"
    debug "$kustomize_command"

    printf "[build] "
    purple "$working_dir"

    set +e
    output=$(eval "$kustomize_command" 2>&1)
    outcome=${PIPESTATUS[0]}
    set -e

    if [ "$outcome" -ne 0 ]; then
      failed
      echo "$output"
      set_exit_code 1
    else
      ok
    fi
  done
}

validate() {
  local kubeconform_flags=(
    "-strict"
    "-ignore-missing-schemas"
    "-kubernetes-version" "$kubernetes_version"
    "-schema-location" "default"
    "-schema-location" "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
    "-summary"
  )

  for pattern in "${kubeconform_ignore_filename_patterns[@]}"; do
    kubeconform_flags+=("-ignore-filename-pattern" "$pattern")
  done

  for kind in "${kubeconform_skip_resources[@]}"; do
    kubeconform_flags+=("-skip" "$kind")
  done

  for file in $(find_kustomization_files "$1"); do
    working_dir=$(dirname "$file")

    kubeconform_command="kubeconform ${kubeconform_flags[*]} -output text $working_dir"
    debug "$kubeconform_command"

    printf "[validate] "
    purple "$working_dir"

    kubeconform_command_json=${kubeconform_command//-output text/-output json}
    errors=$(eval "$kubeconform_command_json | jq '.summary.errors'")
    invalids=$(eval "$kubeconform_command_json | jq '.summary.invalid'")

    if [ "$((errors + invalids))" -ne 0 ]; then
      failed
      set +e
      eval "$kubeconform_command"
      set -e
      set_exit_code 1
    else
      ok
    fi
  done
}

lint() {
  local trivy_flags=(
    "--quiet"
    "--k8s-version" "$kubernetes_version"
    "--exit-code" "1"
    "--ignorefile" "$trivy_ignorefile"
    "--severity" "$trivy_severity"
  )
  for ignored_dir in "${ignored_dirs[@]}"; do
    trivy_flags+=("--skip-dirs" "$ignored_dir")
  done

  for file in $(find_kustomization_files "$1"); do
    working_dir=$(dirname "$file")

    trivy_command="trivy config ${trivy_flags[*]} $working_dir"
    debug "$trivy_command"

    printf "[lint] "
    purple "$working_dir"

    set +e
    output=$(eval "$trivy_command")
    outcome=${PIPESTATUS[0]}
    set -e

    if [ "$outcome" -ne 0 ]; then
      failed
      printf "%s" "$output"
      set_exit_code 1
    else
      ok
    fi
  done
}

user_manual() {
  echo "Usage:"
  echo "  krmc [command] <directory> [flags]"
  echo
  echo "Prerequisites:"
  echo "  - kustomize v5.x"
  echo "  - kubeconform v0.6.x"
  echo "  - trivy v0.50.x"
  echo
  echo "Available Commands:"
  printf "  build\t\tBuilds all kustomizations found under the given directory.\n"
  printf "  check\t\tBuilds, Validates and Lints all kustomizations found under the given directory.\n"
  printf "  lint\t\tLints all kustomizations found under the given directory using trivy.\n"
  printf "  validate\tValidates all kustomizations found under the given directory using kubeconform.\n"
  echo
  echo "Flags:"
  printf "  --ignore-dirs\t\t\t\t\tA comma-separated list of directories to ignore (default: none)\n"
  printf "  --kubeconform-ignore-filename-patterns\tA comma-separated list of regular expression specifying paths that kubeconform will ignore (default: none)\n"
  printf "  --kubeconform-skip-resources\t\t\tA comma-separated list of kinds or GVKs kubeconform will ignore (default: none)\n"
  printf "  --kubernetes-version\t\t\t\tThe kubernetes version to validate against (default: 1.27.4)\n"
  printf "  --trivy-severity\t\t\t\tThe trivy severity to fail on (default: HIGH,CRITICAL,MEDIUM)\n"
  printf "  --trivy-ignorefile\t\t\t\tThe trivy ignorefile to use (default: .trivyignore)\n"
  printf "  --help\t\t\t\t\tHelp for krmc usage\n"
  printf "  --verbose\t\t\t\t\tEnable verbose output\n"
  printf "  --debug\t\t\t\t\tEnable debug output\n"
}

print_settings() {
  purple "KRMC (Kubernetes Resource Model Checker):"
  echo
  printf "command:\t\t%s\n" "$command"
  printf "working dir:\t\t%s\n" "${working_dir[*]}"
  printf "ignored dirs:\t\t%s\n" "${ignored_dirs[*]}"
  echo
}

main() {
  set_exit_code 0

  # default values
  export command="help"
  export working_dir=()
  export ignored_dirs=()

  export kubeconform_ignore_filename_patterns=()
  export kubeconform_skip_resources=()
  export kubernetes_version="1.27.4"
  export kustomize_load_restrictor="LoadRestrictionsNone"
  export trivy_ignorefile=".trivyignore"
  export trivy_severity="HIGH,CRITICAL,MEDIUM"

  export verbose="false"
  export debug="false"

  # parse command
  command=$1

  # parse working dir
  if [[ "$2" =~ ^- ]]; then
    user_manual
    exit 1
  fi
  IFS=',' read -r -a working_dir <<< "$2"

  # Loop through the working_dir and remove trailing slash and leading ./ if present
  for i in "${!working_dir[@]}"; do
      working_dir[$i]=${working_dir[$i]%/}
      working_dir[$i]=${working_dir[$i]#./}
  done

  # parse flags
  for arg in "$@"; do
    case $arg in
      --ignore-dirs=*)
        IFS=',' read -r -a ignored_dirs <<< "${arg#*=}"
        shift
        ;;
      --kubeconform-ignore-filename-patterns=*)
        IFS=',' read -r -a kubeconform_ignore_filename_patterns <<< "${arg#*=}"
        shift
        ;;
      --kubeconform-skip-resources=*)
        IFS=',' read -r -a kubeconform_skip_resources <<< "${arg#*=}"
        shift
        ;;
      --kubernetes-version=*)
        kubernetes_version="${arg#*=}"
        shift
        ;;
      --kustomize-load-restrictor=*)
        kustomize_load_restrictor="${arg#*=}"
        shift
        ;;
      --trivy-ignorefile=*)
        trivy_ignorefile="${arg#*=}"
        shift
        ;;
      --trivy-severity=*)
        trivy_severity="${arg#*=}"
        shift
        ;;
      --verbose)
        verbose="true"
        shift
        ;;
      --debug)
        verbose="true"
        debug="true"
        shift
        ;;
      --help)
        command="help"
        shift
        ;;
      -*|--*)
        echo "Unknown option $arg"
        exit 1
        ;;
      *)
        ;;
    esac
  done

  [ "$verbose" == "true" ] && print_settings

  if [[ "$command" =~ ^(build|check|lint|validate) ]]; then
      for dir in "${working_dir[@]}"; do
        [ "$command" == "check" ] || [ "$command" == "build" ] && build "$dir"
        [ "$command" == "check" ] || [ "$command" == "validate" ] && validate "$dir"
        [ "$command" == "check" ] || [ "$command" == "lint" ] && lint "$dir"
      done
  elif [ "$command" == "help" ]; then
      user_manual
  else
      user_manual
      exit 1
  fi

  exit $(get_exit_code)
}

main "$@"
