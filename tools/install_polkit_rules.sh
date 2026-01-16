#!/bin/bash
#script to install the policykit rules which let manage the rtkbase services without root.
#the user needs to be member of rtkbase group

RTKBASE_USER=$1
[[ -z "${RTKBASE_USER}" ]] && echo 'Please specify a username' && exit 1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OS_ID=''
OS_LIKE=''
PKG_MGR='apt'
POLKIT_PKG='polkitd'

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
fi
OS_ID="${ID:-}"
OS_LIKE="${ID_LIKE:-}"
if [[ "${OS_ID}" == "fedora" ]] || [[ "${OS_LIKE}" == *"fedora"* ]] || [[ "${OS_LIKE}" == *"rhel"* ]]; then
  PKG_MGR='dnf'
  POLKIT_PKG='polkit'
fi

add_polkit_rules() {
  cp "${SCRIPT_DIR}"/polkit/*.rules /etc/polkit-1/rules.d/ && \
  groupadd -f rtkbase                               && \
  usermod -a -G rtkbase "${RTKBASE_USER}"
}

#check if polkit package is available, else exit
if [[ "${PKG_MGR}" == "apt" ]]; then
  apt-cache --quiet=0 show "${POLKIT_PKG}" 2>&1 | grep -q 'No packages found' && exit 1
  #install it if not already installed
  ! dpkg-query -W --showformat='${Status}\n' "${POLKIT_PKG}" >/dev/null 2>&1 && apt-get -y install "${POLKIT_PKG}"
else
  rpm -q "${POLKIT_PKG}" >/dev/null 2>&1 || dnf -y install "${POLKIT_PKG}"
fi
add_polkit_rules
