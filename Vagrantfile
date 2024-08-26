# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-aws 
# vagrant up --provider=aws
# vagrant destroy -f && vagrant up --provider=aws

#-e "playbook_name=ansible-openvpn discord_message_owner_name=terra"
MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/main_amzn2.sh"
TOPIC_NAME = "errors"
ACCOUNT_ID = "992382682634"
AWS_REGION = "il-central-1"
MAIN_SH_ARGS = <<MARKER
-e "playbook_name=ansible-openvpn discord_message_owner_name=#{Etc.getpwuid(Process.uid).name}"
MARKER
Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: <<-SHELL
    set -euxo pipefail
    cd /vagrant
    bash parameters_exist.sh #{MAIN_SH_ARGS}
    # set -euxo pipefail
    # echo "start vagrant file"
    # source /deployment/ansibleenv/bin/activate
    # cd /deployment/playbook
    # export ANSIBLE_VERBOSITY=0
    # export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false
    # export VAULT_PASSWORD=#{`op read "op://Security/ansible-vault inqwise-stg/password"`.strip!}
    # echo "$VAULT_PASSWORD" > vault_password
    # bash main.sh #{MAIN_SH_ARGS}
    # rm vault_password

    # set -euxo pipefail
    # echo "start vagrant file"
    # yum -y erase python3 && amazon-linux-extras install python3.8
    # python3.8 -m venv /tmp/ansibleenv
    # source /tmp/ansibleenv/bin/activate
    # aws s3 cp s3://resource-opinion-stg/get-pip.py - | python3.8
    # cd /vagrant
    # export VAULT_PASSWORD=#{`op read "op://Security/ansible-vault inqwise-stg/password"`.strip!}
    # echo "$VAULT_PASSWORD" > vault_password
    # export ANSIBLE_VERBOSITY=0
    # if [ ! -f "main.sh" ]; then
    # echo "Local main.sh not found. Download main.sh script from URL..."
    # curl -s https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/main_amzn2.sh -o main.sh
    # fi
    # bash main.sh #{MAIN_SH_ARGS}
    # rm vault_password
  SHELL

  config.vm.provider :aws do |aws, override|
  	override.vm.box = "dummy"
    override.ssh.username = "ec2-user"
    override.ssh.private_key_path = "~/.ssh/id_rsa"
    aws.access_key_id             = `op read "op://Security/aws inqwise-stg/Security/Access key ID"`.strip!
    aws.secret_access_key         = `op read "op://Security/aws inqwise-stg/Security/Secret access key"`.strip!
    aws.keypair_name = Etc.getpwuid(Process.uid).name
    override.vm.allowed_synced_folder_types = [:rsync]
    #override.vm.synced_folder ".", "/vagrant", type: :rsync, rsync__exclude: ['.git/','inqwise/'], disabled: false
    #common_collection_path = ENV['COMMON_COLLECTION_PATH'] || '~/git/ansible-common-collection'
    #stacktrek_collection_path = ENV['COMMON_COLLECTION_PATH'] || '~/git/ansible-stack-trek'
    #override.vm.synced_folder common_collection_path + '/inqwise/common', '/vagrant/collections/ansible_collections/inqwise/common', type: :rsync, rsync__exclude: '.git/', disabled: false
    #override.vm.synced_folder stacktrek_collection_path + '/inqwise/stacktrek', '/vagrant/collections/ansible_collections/inqwise/stacktrek', type: :rsync, rsync__exclude: '.git/', disabled: false

    #aws.user_data = File.read("user_data.txt")
    aws.region = AWS_REGION
    aws.security_groups = ["sg-0cbd632d37524e9fe","sg-020afd8fd0fa9fd0b"]
    aws.ami = "ami-06df040a3b7ab6af4"
    aws.instance_type = "t3.micro"
    aws.subnet_id = "subnet-0f46c97c53ea11e2e"
    aws.associate_public_ip = true
    aws.iam_instance_profile_name = "bootstrap-role"
    aws.tags = {
      Name: "openvpn-test-#{Etc.getpwuid(Process.uid).name}",
      playbook_name: "ansible-openvpn",
      version: "latest",
      app: "openvpn",
      public_dns: "vpn-golden-test",
      private_dns: "vpn-golden-test"
    }
  end
end

#ami-00e65230f6b0a8dcf