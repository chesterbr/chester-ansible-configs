# chester-ansible-configs

This project contains the configuration for my personal projects (which I automated in an effort to further explore [Ansible][7], [Vagrant][12] and related tools), and published because:

- Ansible exemples may be useful to someone else (despite being very specific to my stuff);
- It keeps me honest (makes me write scripts that don't suck much, forces me not to have plaintext secrets, exposes security flaws, etc.);
- Public github is free! ;-)

Feel free to use it (I'm licensing as MIT to ensure that) and to open issues or [contact me][6] if you find something awry.

If you want to learn Ansible, I strongly recommend [Jeff Geerling][11]'s [Ansible for DevOps][8]. Several tasks here were based on tasks on his book or some of [his tasks in Ansble Galaxy](15).

(Se você lê Português, veja também o [Caixa de Ferramentas DevOps][9] do [Gleicon Moraes][10])

## What does it configure?

### chester.me (blog)

My [personal blog][4], currently based on a [forked Octopress 2.x][5].

### cruzalinhas.com

An app that allows quickly finding public transportation routes in São Paulo. See [source code][1] or [website][3] for details. It shares she same nginx with the blog above.

### Toronto Transit for Pebble

Back-end for a Pebble app that finds the nearest bus/streetcar stops and shows how long it will take for the next vehicles to arrive.

### miniTruco server [TODO]

This is a simple Java app that listens on the 6912 port, handling communication between [miniTruco][2] clients and spawning bot players to fill incomplete tables (a miniTruco table requires 4 players).

## Quick setup (Mac OS X)

This will get you a VM capable of running any of those services:

```
brew install rbenv ansible
brew cask install virtualbox vagrant
vagrant up
```

To install one (or more) of the services on the machine, run its playbook with the generated inventory:

```
ansible-playbook blog.yml -i localhost:2222,
```

(alternatively you can use `-i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`, but it will log in with the default user for Ubuntu provisioning, not the `{{ admin_user }}` defined on the global vars)

Point the "dev" version of the site to your local machine on `/etc/hosts`, e.g.:

```
127.0.0.1 dev.chester.me
127.0.0.1 dev.cruzalinhas.com
127.0.0.1 dev.totransit.chester.me
```

and open the site on port 8080 (http://dev.chester.me:8080)

### Passwords vault

A few tasks may require you to supply your own [password vault][13]. See [the sample file][14] for details.

### Third party roles

I used to have third party roles downloaded from Ansible Galaxy, but a few tend not to be maintained (or accept patches) very often (and Galaxy itself seems not to be very active - for example, a command to update roles is [two years in the wait](https://github.com/ansible/ansible/issues/6466)). Given the upcoming Ansible 2.0 changes, I followed the advice from experienced sysadmins: moved those roles inside and will eventually internalize their tasks to my particular case.

### Maintenance tasks

Those are tagged on the playbooks, please check them for such tags and add to `ansible-playbook`. Examples:

- To download new data from sptrans: `--tags update_sptrans_data`;
- To publish the blog from its repository: `--tags publish_blog`;
- To deploy the latest master of cruzalinhas or toronto-transit-time: `--tags update_app`.


[1]: https://github.com/chesterbr/cruzalinhas
[2]: https://github.com/chesterbr/minitruco-j2me
[3]: http://cruzalinhas.com
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
[14]: https://github.com/chesterbr/chester-ansible-configs/blob/master/roles/chesterbr.vault/vars/vault.yml.SAMPLE
[15]: https://galaxy.ansible.com/geerlingguy/

## License

chester-ansible-configs - Copyright (c) 2015 Carlos Duarte do Nascimento (Chester)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
