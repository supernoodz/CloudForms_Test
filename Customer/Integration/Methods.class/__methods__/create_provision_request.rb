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
# 
def exec_provision_request(image, vm_name, memory, cores, network, dns_servers, parent_service_id, install_app)
  url = URI.encode(API_URI + "/provision_requests")

  post_params = {
    :version   => "1.1",
    :template_fields => {
      :guid              => image.guid
    },
    :vm_fields => {
      :number_of_cpus    => cores.to_s,
      :number_of_sockets => 1.to_s,
      :vm_name           => vm_name,
      :vm_memory         => (memory.to_i * 1024).to_s, #needs to be in MB
      :vlan              => network,
      :sysprep_custom_spec   => ["1000000000004", "default Linux"],
      :sysprep_enabled   => ["fields", "Specification"],
      :dns_servers       => dns_servers
    },
    :requester => {
      :user_name         => "admin",
      :owner_first_name  => "John",
      :owner_last_name   => "Doe",
      :owner_email       => "jdoe@sample.com",
      :auto_approve      => true
    },
    :tags => { },
    :additional_values => {
      :service_id        => parent_service_id,
      :install_app       => install_app
    },
    :ems_custom_attributes => { },
    :miq_custom_attributes => { }
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
  # $evm.log(:info, "VM Name: #{vm_name}")
  vm_name
end

# def check_provision_request(request_id)
#   url = URI.encode(API_URI + "/provision_requests/#{request_id}")

#   rest_return = RestClient::Request.execute(
#     method:     :get,
#     url:        url,
#     :headers    => {
#       :accept => :json,
#       'x-auth-token' => @auth_token
#     },
#     verify_ssl: false)
#   result = JSON.parse(rest_return)

#   # result['request_state']
#   # result['action']
#   result['reason']
# end

require 'rest-client'

API_URI     = 'https://localhost/api'
USER        = 'admin'
PASSWORD    = 'smartvm'
@auth_token = get_auth

task = $evm.root['service_template_provision_task']
task ? parent_service_id = task.destination.id : parent_service_id = nil

# owner = $evm.root['user']

# key_pair and security_group - Processed by amazon_CustomizeRequest, expects name.

# image_ems_ref = "vm-71" # 'RHEL 7.3' template

image_ems_ref = $evm.root['dialog_template']
image_ems_ref = image_ems_ref.gsub(/_/,'-')

image = $evm.vmdb(:VmOrTemplate).find_by(:ems_ref => image_ems_ref)
raise 'Image not found' if image.nil?

number_of_vms = $evm.root['dialog_number_of_vms']
number_of_vms ? number_of_vms = number_of_vms.to_i : number_of_vms = 1

dns_servers = $evm.root['dialog_dns_servers']

cpus    = 2
memory  = 2 #GB
# network = '523 - UCS_GESTION'
network = '524'

vm_name = 'vf001'
vm_name = get_vm_name(vm_name)

# https://github.com/ManageIQ/manageiq_docs/blob/master/api/reference/provision_requests.adoc
1.upto(number_of_vms) do |i|
  if $evm.root.attributes.has_key?("dialog_option_#{i}_app")
    install_app = $evm.root["dialog_option_#{i}_app"]
  else
    install_app = 'none'
  end
  # vm_name = get_vm_name(vm_name)
  $evm.log(:info, "VM Name: #{vm_name}")
  exec_provision_request(
    image,
    vm_name,
    memory,
    cpus,
    network,
    dns_servers,
    parent_service_id,
    install_app
  )
  vm_name = vm_name.succ
end
