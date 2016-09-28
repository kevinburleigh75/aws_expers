#!/usr/bin/env ruby

Bundler.require

require 'csv'

CSV.foreach('credentials.csv', headers: :first_row) do |row|
  ENV['AWS_ACCESS_KEY_ID']     = row.fetch('Access Key Id')
  ENV['AWS_SECRET_ACCESS_KEY'] = row.fetch('Secret Access Key')
end

ec2 = Aws::EC2::Resource.new(region: 'us-west-2')

script = %Q{
  #!/bin/bash

  touch ~ec2-user/user_data_executed.txt

  cat > ~ec2-user/init.sh <<EOF
    #!/bin/bash
    cd ~ec2-user
    git clone https://github.com/kevinburleigh75/aws_expers.git
    cd aws_expers
    gem install bundler
    bundler install
    bundle exec ./exper2/the_script.rb
  EOF

  chmod 744 ~ec2-user/init.sh
  chown ec2-user ~ec2-user/init.sh

  runuser -l ec2-user -c 'cd; ./init.sh'
}

encoded_script = Base64.encode64(script)

puts "#{Time.now}: creating instance..."
instance = ec2.create_instances(
  {
    image_id: 'ami-6c07d70c',
    min_count: 1,
    max_count: 1,
    key_name: 'kevin_exper_kp',
    security_group_ids: ['sg-f9907f80'],
    user_data: encoded_script,
    instance_type: 't2.micro',
    placement: {
      availability_zone: 'us-west-2c'
    },
    subnet_id: 'subnet-7c344c25',
    iam_instance_profile: {
      arn: 'arn:aws:iam::714205614004:instance-profile/KevinRole1'
    }
  }
).first

# Name the instance and give it a group
instance_name = "Monitor#{Kernel::rand(100)}"
puts "#{Time.now}: adding tags to #{instance_name}..."
instance.create_tags(
  {
    tags: [
      { key:   'Name',
        value: instance_name },
      { key:   'Group',
        value: 'Monitors' }
    ]
  }
)

# Wait for the instance to be created, running, and passed status checks
puts "#{Time.now}: waiting for instance to pass checks..."
ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance.id]})

puts "#{Time.now}: some extra info"
puts instance.id
puts instance.public_ip_address
