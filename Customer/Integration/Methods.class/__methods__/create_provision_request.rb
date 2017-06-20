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
def exec_provision_request(image, memory, cores, vlan, parent_service_id, install_app)
  url = URI.encode(API_URI + "/provision_requests")

  post_params = {
    :version   => "1.1",
    :template_fields => {
      :guid              => image.guid
    },
    :vm_fields => {
      :number_of_cpus    => cores.to_s,
      :number_of_sockets => 1.to_s,
      :vm_name           => "changeme",
      :vm_memory         => memory.to_s,
      :vlan              => vlan,
      # :sysprep_custom_spec   => '',
      # :sysprep_spec_override => 1,

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

API_URI     = 'https://192.168.33.129/api'
USER        = 'admin'
PASSWORD    = 'smartvm'
@auth_token = get_auth

task = $evm.root['service_template_provision_task']
task ? parent_service_id = task.destination.id : parent_service_id = nil

parent_service_id = nil

# owner = $evm.root['user']

# key_pair and security_group - Processed by amazon_CustomizeRequest, expects name.

image_ems_ref = "vm-388"

image = $evm.vmdb(:VmOrTemplate).find_by(:ems_ref => image_ems_ref)
raise 'Image not found' if image.nil?

number_of_vms = $evm.root['dialog_number_of_vms']
number_of_vms ? number_of_vms = number_of_vms.to_i : number_of_vms = 1

# https://github.com/ManageIQ/manageiq_docs/blob/master/api/reference/provision_requests.adoc
1.upto(1) do |i|
  if $evm.root.attributes.has_key?("dialog_option_#{i}_app")
    install_app = $evm.root["dialog_option_#{i}_app"]
  else
    install_app = 'none'
  end
  exec_provision_request(image, 2, 2, 'VM Network', parent_service_id, install_app)
end
