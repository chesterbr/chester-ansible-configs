# chester-ansible-configs

This project contains the configuration for my personal projects (which I automated in an effort to further explore [Ansible][7], [Vagrant][12] and related tools), and published because:

- Ansible examples may be useful to someone else (despite being very specific to my stuff);
- It keeps me honest (makes me write scripts that don't suck much, forces me not to have plaintext secrets, exposes security flaws, etc.);
- ~Public github is free~ [Not really a reason anymore](https://github.blog/2019-01-07-new-year-new-github/) 🎉

Feel free to use it (I'm licensing as MIT to ensure that) and to open issues or [contact me][6] if you find something awry.

If you want to learn Ansible, I strongly recommend [Jeff Geerling][11]'s [Ansible for DevOps][8]. Several tasks here were based on tasks on his book or some of [his tasks in Ansible Galaxy][15].

(Se você lê Português, veja também o [Caixa de Ferramentas DevOps][9] do [Gleicon Moraes][10])

## What does it configure?

### cruzalinhas

An app that allows quickly finding public transportation routes in São Paulo. See [source code][1] or [website][3] for details. It shares the same nginx with the Toronto Transit (below).

### Toronto Transit for Pebble

Back-end for a Pebble app that finds the nearest bus/streetcar stops and shows how long it will take for the next vehicles to arrive.

### miniTruco server

This is a simple Java app that listens on the 6912 port, handling communication between [miniTruco][2] clients and spawning bot players to fill incomplete tables (a miniTruco table requires 4 players).

## How the repo is organized

Everything runs on a single server: all playbooks target the `production` group in `hosts`, which currently has a single machine.

- `hosts`: the Ansible inventory. The server is `prod.chester.me`, a DNS record used only to reach it (the apps have their own records, see below), so the GitHub Actions deploys of the apps follow it too. Keep `ansible_python_interpreter=/usr/bin/python3` on the host line (the default in `group_vars/all.yml` is stale).
- `group_vars/all.yml`: shared settings (admin and server users, checkout directories, miniTruco port and rate limits).
- `provisioning.yml`: one-time base setup (admin user, ssh hardening, firewall, fail2ban, unattended upgrades, swap). Runs as `root`.
- `cruzalinhas.yml`, `totransit.yml`, `minitruco.yml`: one playbook per app.
- `roles/chesterbr.*`: `user_setup`, `security`, `swapfile` (used by provisioning); `nginx`, `ruby` (rbenv), `vault` (loads the encrypted variables) used by the app playbooks.
- `templates/`: supervisor programs (`*.conf.supervisor.j2`), the miniTruco firewall rate limit and log rotation.

How the server works:

- Apps run as the non-login `server` user under supervisor, and are deployed from the `main` branch of their own GitHub repos.
- nginx (port 80, plain HTTP) proxies to Puma on port 3000 (cruzalinhas) and 3001 (Toronto Transit). miniTruco listens on 6912 directly.
- The SQLite databases are rebuilt by the playbooks (`sptrans:import` for cruzalinhas, `ttc:crawl` for Toronto Transit), so there is no data to migrate or back up.
- If the server needs a reboot after updates, it happens at 05:00 UTC, after stopping the services (it waits up to 30 minutes for miniTruco games to finish).
- Playbooks are meant to be idempotent, so re-running one is safe.
- Secrets live only in the encrypted vault (below); nothing sensitive is committed in plaintext.

## Setup and operation

### Passwords vault

A few tasks require you to supply your own [password vault][13]. See [the sample file][14] for details. `cruzalinhas.yml` and `minitruco.yml` load it; `provisioning.yml` and `totransit.yml` do not. Give Ansible the vault password with `--ask-vault-pass`, or with `export ANSIBLE_VAULT_PASSWORD_FILE=<path to a file or script that prints the password>`.

### Production (re)provisioning

You need Ansible on your machine (`brew install ansible` includes the `community.general` collection that the ruby role uses). To create (or replace) the server:

1. Spawn the new server (any cheap VPS running the latest LTS Ubuntu will do);
2. Point `prod.chester.me`, and only it, to the new IP. Check that it resolves (`dig +short prod.chester.me`) and that ssh reaches the new machine (`ssh root@prod.chester.me hostname`; if ssh complains about a changed host key, run `ssh-keygen -R prod.chester.me`);
3. Run the initial `provisioning.yml` with the `root` user. Add `-k` if the VPS gave you a root password (instead of using your ssh key);
4. From this point on, the server disables password/root logins; the users for admin and for server processes are created; and the admin (`admin_user`) gets the ssh keys published at `admin_user_key` (a GitHub keys URL set in `group_vars/all.yml`), so you can ssh and run the other playbooks securely;
5. Run the app playbooks (below), then check the new server before it gets any traffic: `curl -H "Host: cruzalinhas.chester.me" http://prod.chester.me/` (same for `totransit.chester.me`), `nc -vz prod.chester.me 6912`, and `sudo supervisorctl status` on the server;
6. Point the app domains to the new IP: `cruzalinhas`, `totransit` and `minitruco` under `chester.me`. The `chester.me` apex is the blog on GitHub Pages, leave it alone. Once that is done, cancel the old server's renewal.

Run the playbooks one at a time (the app playbooks log in as `admin_user`, so no `-u`):

```
ansible-playbook provisioning.yml -i hosts -u root
ansible-playbook cruzalinhas.yml  -i hosts
ansible-playbook totransit.yml    -i hosts
ansible-playbook minitruco.yml    -i hosts
```

The first run of `cruzalinhas.yml` and `totransit.yml` downloads and imports the transit data, which takes a few minutes of CPU.

To run any playbook against a specific IP without touching DNS, add `-e ansible_host=<IP>` (it overrides the address of the inventory host).

### Maintenance tasks

Tasks are tagged in the playbooks; add `--tags` to `ansible-playbook` to run only those. Examples:

- To download new data from sptrans: `ansible-playbook cruzalinhas.yml -i hosts --tags update_sptrans_data`;
- To deploy the latest version of cruzalinhas, minitruco or toronto-transit-time: `ansible-playbook <playbook>.yml -i hosts --tags update_app`;
- Other tags: `configure_supervisor` (all app playbooks), `firewall` (`minitruco.yml`) and `load_ttc_data` (`totransit.yml`).

## Local development server (Mac OS X)

Heads up: this section is not maintained. The `Vagrantfile` targets Ubuntu 16.04 (`ubuntu/xenial64`) on VirtualBox, and the `config-dev-environment` script it used to mention does not exist in this repo.

This is meant to get you a VM capable of running any of those services:

```
brew update
brew install rbenv ansible
brew install --cask virtualbox vagrant
vagrant up
```

To install one (or more) of the services on the virtual machine, add the proper IP in `hosts`, then run the playbook:

```
ansible-playbook <playbook name>.yml -i hosts
```

(alternatively you can use `-i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`, but it will log in with the default user for Ubuntu provisioning, not the `admin_user` defined on the global vars)

## Older scripts (not on main branch anymore)

### Home automation Raspberry Pi

Before switching to [Home Assistant](https://www.home-assistant.io/), I manually configured my RPi to add voice control to my [lights](https://chester.me/archives/2017/12/controlling-rf-outlets-from-a-raspberry-pi/) and [TV](https://chester.me/archives/2017/12/voice-control-for-a-non-smart-tv-with-google-home-raspberry-pi-lirc-nginx-lua-ifttt/), among other home automation tasks. For that I had playbooks to [provision](https://github.com/chesterbr/chester-ansible-configs/blob/36c13da4df04f51c54cab9d2d7b0e228300f8843/rpi_provisioning.yml) it and [configure the apps](https://github.com/chesterbr/chester-ansible-configs/blob/36c13da4df04f51c54cab9d2d7b0e228300f8843/rpi.yml), so I could tinker with confidence. Some of its leftovers lived on in `templates/` until later: the Home Assistant [backup script](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/templates/ha-backup.sh.j2) and [service unit](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/templates/homeassistant.service.j2), the [DuckDNS updater](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/templates/duck.sh.j2), the [certificate copy script](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/templates/update_and_copy_certificates.sh.j2) and the [fail2ban config](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/templates/jail.local.j2).

### staticman

A fork of [Staticman](https://staticman.net/) that I used to handle comments on my [blog][4]. It's a Node.js app that listened on port 3002, and is no longer deployed here. See the [playbook](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/staticman.yml), its [supervisor config](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/templates/staticman.conf.supervisor.j2) and [infrastructure config](https://github.com/chesterbr/chester-ansible-configs/blob/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/templates/staticman_infrastructure_config.json.j2).

### Let's Encrypt role

The [`chesterbr.letsencrypt` role](https://github.com/chesterbr/chester-ansible-configs/tree/847d79b9c72ff3f0fd1fe69f2d0f7eb0ad7b7ff2/roles/chesterbr.letsencrypt), which obtained Let's Encrypt certificates in production (and a self-signed one for development).

[1]: https://github.com/chesterbr/cruzalinhas
[2]: https://github.com/chesterbr/minitruco-android
[3]: http://cruzalinhas.chester.me
[4]: http://chester.me
[5]: https://github.com/chesterbr/octopress
[6]: mailto:cd@pobox.com?subject=chester-website-configs
[7]: http://www.ansible.com
[8]: https://leanpub.com/ansible-for-devops
[9]: http://www.casadocodigo.com.br/products/livro-ferramentas-devops
[10]: https://github.com/gleicon
[11]: https://github.com/geerlingguy
[12]: https://www.vagrantup.com/
[13]: http://docs.ansible.com/ansible/playbooks_vault.html
[14]: https://github.com/chesterbr/chester-ansible-configs/blob/main/roles/chesterbr.vault/vars/vault.yml.SAMPLE
[15]: https://galaxy.ansible.com/geerlingguy/
