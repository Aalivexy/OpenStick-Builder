#!/bin/bash
[ "$1" = root ] || {
    [ -f /var/lib/first-setup.done ] && return
    [ -t 0 ] || return
    [ "$(id -un)" = user ] || return
    exec sudo -i /bin/bash /etc/profile.d/zz-first-setup.sh root
}

name=
while :; do
    printf "Username: "
    read name || exit 130
    case "$name" in
        '' | *[!a-z0-9_-]* | [-_0-9]*) echo "only a-z, 0-9, '-' and '_' allowed" >&2; continue ;;
    esac
    getent passwd "$name" >/dev/null && { echo "$name already exists" >&2; continue; }
    break
done

key=
while :; do
    printf "SSH public key: "
    read key || exit 130
    case "$key" in
        ssh-ed25519* | ssh-rsa* | ecdsa-sha2-* | sk-ssh-ed25519* | sk-ecdsa-sha2-*) ;;
        *) echo "invalid public key" >&2; continue ;;
    esac
    case "$key" in *' '*) ;; *) echo "invalid public key" >&2; continue ;; esac
    break
done

useradd -m -U -s /bin/bash "$name" || exit 1
mkdir -p "/home/$name/.ssh"
echo "$key" > "/home/$name/.ssh/authorized_keys"
chmod 700 "/home/$name/.ssh"
chmod 600 "/home/$name/.ssh/authorized_keys"
chown -R "$name:$name" "/home/$name/.ssh"

rm -f /etc/sudoers.d/user
echo "$name ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$name
chmod 440 /etc/sudoers.d/$name

cd /
userdel -f -r user || { passwd -l user; rm -rf /home/user; }

touch /var/lib/first-setup.done

printf '\nReconnect as %s\n' "$name"
exit 0