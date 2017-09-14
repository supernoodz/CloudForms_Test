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
    # :version   => "1.1",
    :template_fields => {
      # :guid             => image.guid,
      :name             => "RHEL-7.4_HVM_Beta-20170518-x86_64-1-Hourly2-GP2",
      :request_type     => 'template'
    },
    :vm_fields => {
      # :addr_mode        => ["dhcp", "DHCP"],
      # :cloud_network    => ["3", "HybridCloud_MGMT (10.100.0.0/16)"],
      # :cloud_subnet     => ["3", "Private (10.100.1.0/24) | eu-west-2a"],
      # :instance_type    => 163,  # ["163", "t2.micro: T2 Micro"],
      :instance_type    => 212, # "t2.small"
      # :monitoring       => ["basic", "Basic"],
      # :placement_availability_zone => ["2", "eu-west-2a"],
      # :security_groups  => "6",
      :vm_name          => get_vm_name('shell001'),
      :placement_auto   => true
    },
    :requester => {
      :user_name         => USER,
      :owner_first_name  => "John",
      :owner_last_name   => "Doe",
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
      :accept => :json,
      'x-auth-token' => @auth_token
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
USER        = 'admin'
PASSWORD    = 'smartvm'
@auth_token = get_auth

task = $evm.root['service_template_provision_task']
task ? parent_service_id = task.destination.id : parent_service_id = nil

# key_pair and security_group - Processed by amazon_CustomizeRequest, expects name.

# image_ems_ref = $evm.root['dialog_template']
# image_ems_ref = image_ems_ref.gsub(/_/,'-')

# image_ems_ref = "ami-d76170b3" # "RHEL-7.4_HVM_GA-20170724-x86_64-1-Hourly2-GP2"

# image = $evm.vmdb(:VmOrTemplate).find_by(:ems_ref => image_ems_ref)
# raise 'Image not found' if image.nil?

# vm_name = get_vm_name('shell001')

# https://github.com/ManageIQ/manageiq_docs/blob/master/api/reference/provision_requests.adoc

# $evm.log(:info, "VM Name: #{vm_name}")
exec_provision_request(parent_service_id)
