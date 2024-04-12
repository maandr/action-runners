#!/bin/bash

set -o errexit

color_red='\033[0;31m'
color_green='\033[0;32m'
color_purple='\033[1;35m'
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

set_exit_code() {
  echo "$1" > /tmp/kubeml_exit_code
}

get_exit_code() {
  cat /tmp/kubeml_exit_code
}

find_kustomization_files() {
  find "$1" -type f \( -name "kustomization.yaml" -o -name "kustomization.yml" \) -print0
}

# Build
build() {
  local kustomize_flags=(
    "--load-restrictor=$kustomize_load_restrictor"
  )

  find_kustomization_files "$1" | while IFS= read -r -d $'\0' file;
    do
      working_dir=$(dirname "$file")

      printf "[build] "
      purple "$working_dir"

      set +e
      output=$(kustomize build "$working_dir" "${kustomize_flags[@]}" 2>&1)
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

# Validate
validate() {
  kubeconform_flags=(
    "-strict"
    "-ignore-missing-schemas"
    "-kubernetes-version" "$kubernetes_version"
    "-schema-location" "default"
    "-schema-location" "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
    "-summary"
    "-ignore-filename-pattern" ".*gotk-.*"
    "-ignore-filename-pattern" ".*.sops.yaml"
    "-skip" "Secret"
  )

  find_kustomization_files "$1" | while IFS= read -r -d $'\0' file;
    do
      working_dir=$(dirname "$file")

      printf "[validate] "
      purple "$working_dir"

      errors=$(kubeconform "${kubeconform_flags[@]}" -output json "$working_dir" | jq '.summary.errors')
      invalids=$(kubeconform "${kubeconform_flags[@]}" -output json "$working_dir" | jq '.summary.invalid')

      if [ "$((errors + invalids))" -ne 0 ]; then
        failed
        set +e
        kubeconform "${kubeconform_flags[@]}" -output text "$working_dir"
        set -e
        set_exit_code 1
      else
        ok
      fi
  done
}

# Lint
lint() {
  trivy_flags=(
    "--quiet"
    "--k8s-version" "$kubernetes_version"
    "--exit-code" "1"
    "--ignorefile" "$trivy_ignorefile"
    "--severity" "$trivy_severity"
  )

  find_kustomization_files "$1" | while IFS= read -r -d $'\0' file;
    do
      working_dir=$(dirname "$file")

      printf "[lint] "
      purple "$working_dir"

      set +e
      output=$(trivy config "${trivy_flags[@]}" "$working_dir")
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
  printf "  --kubernetes-version\t\tThe kubernetes version to validate against. (default: 1.27.4)\n"
  printf "  --kustomize-load-restrictor\tThe kustomize load restrictor to use. (default: LoadRestrictionsNone)\n"
  printf "  --trivy-severity\t\tThe trivy severity to fail on. (default: HIGH,CRITICAL,MEDIUM)\n"
  printf "  --trivy-ignorefile\t\tThe trivy ignorefile to use. (default: .trivyignore)\n"
  printf "  --help\t\t\tHelp for krmc usage.\n"
  printf "  -v, --verbose\t\t\tEnable verbose output.\n"
}

print_settings() {
  purple "KRMC (Kubernetes Resource Model Checker):"
  echo
  printf "command:\t\t\t%s\n" "$command"
  printf "working dir:\t\t\t%s\n" "$working_dir"
  echo
  printf "kubernetes-version:\t\t%s\n" "$kubernetes_version"
  printf "kustomize-load-restrictor:\t%s\n" "$kustomize_load_restrictor"
  printf "trivy-severity:\t\t\t%s\n" "$trivy_severity"
  printf "trivy-ignorefile:\t\t%s\n" "$trivy_ignorefile"
  echo
}

main() {
  set_exit_code 0

  # options
  export command="help"
  export working_dir="."
  export kustomize_load_restrictor="LoadRestrictionsNone"
  export kubernetes_version="1.27.4"
  export trivy_severity="HIGH,CRITICAL,MEDIUM"
  export trivy_ignorefile=".trivyignore"
  export verbose="false"

  # parse command
  command=$1
  # parse working dir
  working_dir=${2%/}
  # parse flags
  for arg in "$@"; do
    case $arg in
      --kubernetes-version=*)
        kubernetes_version="${arg#*=}"
        shift # past argument=value
        ;;
      --kustomize-load-restrictor=*)
        kustomize_load_restrictor="${arg#*=}"
        shift # past argument=value
        ;;
      --trivy-severity=*)
        trivy_severity="${arg#*=}"
        shift # past argument=value
        ;;
      --trivy-ignorefile=*)
        trivy_ignorefile="${arg#*=}"
        shift # past argument=value
        ;;
      -v|--verbose)
        verbose="true"
        shift # past argument=value
        ;;
      --help)
        command="help"
        shift # past argument=value
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

  if [ "$command" == "build" ]; then
      build "$working_dir"
  elif [ "$command" == "validate" ]; then
      validate "$working_dir"
  elif [ "$command" == "lint" ]; then
      lint "$working_dir"
  elif [ "$command" == "check" ]; then
      build "$working_dir"
      validate "$working_dir"
      lint "$working_dir"
  elif [ "$command" == "help" ]; then
      user_manual
  else
      user_manual
      exit 1
  fi

  exit $(get_exit_code)
}

main "$@"
