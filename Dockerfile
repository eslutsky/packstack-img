FROM quay.io/centos/centos:stream8

MAINTAINER "Evgeny Slutsky" <eslutsky@redhat.com>

ENV container docker
STOPSIGNAL SIGRTMIN+3

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
  /etc/systemd/system/*.wants/* \
  /lib/systemd/system/local-fs.target.wants/* \
  /lib/systemd/system/sockets.target.wants/*udev* \
  /lib/systemd/system/sockets.target.wants/*initctl* \
  /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
  /lib/systemd/system/systemd-update-utmp*

RUN dnf update -y
RUN dnf config-manager --enable powertools
RUN dnf install -y centos-release-openstack-yoga
RUN dnf install -y openstack-packstack net-tools iproute
RUN dnf install -y openssh-server procps-ng audit policycoreutils kmod wget lvm2 socat
RUN systemctl enable sshd

# locking to specific libvirt version due to https://github.com/kubev2v/packstack-img/issues/5
RUN dnf install python3-dnf-plugin-versionlock -y 
RUN dnf versionlock libvirt-daemon-8.0.0-10.* libvirt-daemon-config-nwfilter-8.0.0-10.*


# Copy answer file
ADD files/packstack.answer /packstack.answer
ADD files/auditd.service /usr/lib/systemd/system/auditd.service

ADD files/deploy-packstack.sh /deploy-packstack.sh
ADD files/socat-nfs.service /usr/lib/systemd/system/socat-nfs.service
ADD files/run_socat.sh /run_socat.sh
RUN systemctl enable socat-nfs
# Copy fake audit service config /usr/lib/systemd/system/auditd.service

VOLUME [ "/tmp", "/run", "/run/lock" ]

CMD ["/lib/systemd/systemd", "log-level=info", "unit=sysinit.target"]
