#
# Description: <Method description here>
#

def get_auth
  url = URI.encode(API_URI + '/auth')

  rest_return = RestClient::Request.execute(
    method:     :get,
    url:        url,
    :user       => USER,
    :password   => PASSWORD,
    :headers    => {:accept => :json},
    verify_ssl: false)

  JSON.parse(rest_return)['auth_token']
end

def exec_provision_request(parent_service_id)
  url = URI.encode(API_URI + "/provision_requests")

  post_params = {
    :template_fields => {
      :name         => "RHEL-7.4_HVM_Beta-20170518-x86_64-1-Hourly2-GP2",
      :request_type => 'template'
    },
    :vm_fields => {
      # :cloud_network                => 3,   # ["3", "HybridCloud_MGMT (10.100.0.0/16)"],
      # :cloud_subnet                 => 3,   # ["3", "Private (10.100.1.0/24) | eu-west-2a"],
      # :instance_type                => 163, # ["163", "t2.micro: T2 Micro"],
      # :placement_availability_zone  => 2,   # ["2", "eu-west-2a"],
      # :security_groups              => 6,

      :cloud_network                => 12,  # [12, "vpc-83d32ee6 (172.31.0.0/16)"],
      :cloud_subnet                 => 9,   # [9, "subnet-2fbd5876 (172.31.0.0/20) | eu-west-1a"],
      ## :dest_availability_zone       => 5,   # [5, "eu-west-1a"],
      ## :guest_access_key_pair        => 16,  # [16, "july2017"],
      :instance_type                => 212, # [212, "t2.small: T2 Small"]]
      :placement_availability_zone  => 5,   # [5, "eu-west-1a"],
      :security_groups              => 8,

      :addr_mode                    => ["dhcp", "DHCP"],
      :monitoring                   => ["basic", "Basic"],
      :placement_auto               => false,
      :vm_name                      => get_vm_name('shell001')
    },
    :requester => {
      :user_name         => USER,
      :owner_email       => "jdoe@sample.com",
      :auto_approve      => true
    },
    # :tags => { },
    :additional_values => {
      :service_id        => parent_service_id
    },
    # :ems_custom_attributes => { },
    # :miq_custom_attributes => { }
  }.to_json

  rest_return = RestClient::Request.execute(
    method:     :post,
    url:        url,
    :headers    => {
      :accept         => :json,
      'x-auth-token'  => @auth_token
    },
    :payload    => post_params,
    verify_ssl: false)

  result = JSON.parse(rest_return)
  result['results'][0]['id']
end

def exec_service_template()
  url = URI.encode(API_URI + "/service_catalogs/1/service_templates")

  post_params = {
    :action => "order", 
    :resource => {
      :href                      => "#{url}/1", # 101-vm-simple-linux
      :stack_name                => "brah001",
      :resource_group            =>  "cfme42beta1",
      :deploy_mode               => "Incremental",
      :param_adminUsername       => "redhat",
      :param_adminPassword       => "v2:{ndDS6zoA1bDX21L8+R2lGw==}",
      :param_dnsLabelPrefix      => "brah",
      :param_ubuntuOSVersion     => "16.04.0-LTS"

      # :href                      => "#{url}/2",  # "Azure VM - Windows 2016 Datacenter"
      # :stack_name                => "Test",
      # :resource_group            =>  "RG-HCM-Test",
      # :deploy_mode               => "Incremental",
      # :param_virtualMachineName  => get_vm_name("AZU-SVR123"),
      # :param_adminUsernameparam_virtualMachineSize  => "basic_a1",
      # :param_adminUsername       => "rutger",
      # :param_adminPassword       => "v2:{l0ddco2EdZ9uFaZjRxMKXQ==}"
    }
  }.to_json

  rest_return = RestClient::Request.execute(
    method:     :post,
    url:        url,
    :headers    => {
      :accept         => :json,
      'x-auth-token'  => @auth_token
    },
    :payload    => post_params,
    verify_ssl: false)

  result = JSON.parse(rest_return)
  result['results'][0]['id']
end

def get_vm_name(vm_name)
  vm = $evm.vmdb(:Vm).find_by(:name=>vm_name)
  while vm
    vm_name = vm_name.succ
    vm = $evm.vmdb(:Vm).find_by(:name=>vm_name)
  end
  $evm.log(:info, "VM Name: #{vm_name}")
  vm_name
end

require 'rest-client'

API_URI     = 'https://localhost/api'
USER        = $evm.object['cf_user']
PASSWORD    = $evm.object.decrypt('cf_password')
USER        = 'admin'
PASSWORD    = 'smartvm'
@auth_token = get_auth

task = $evm.root['service_template_provision_task']
task ? parent_service_id = task.destination.id : parent_service_id = nil

destination = $evm.root['dialog_destination']

unless destination.nil?
  $evm.log(:info, "destination: #{destination}")
  case destination
  when "cheap"
    # Amazon
    exec_provision_request(parent_service_id)
  when "expensive"
    # Azure
    exec_service_template()
  end
end
