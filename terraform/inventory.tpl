[qr_forge_servers]
qr-forge-server ansible_host=${instance_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/qr-forge.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[qr_forge_servers:vars]
ansible_python_interpreter=/usr/bin/python3
