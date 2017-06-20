
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

def exec_automation_request(playbook, host, credential)
  url = URI.encode(API_URI + "/automation_requests")

  post_params = {
    :version => '1.1',
    :uri_parts => {
      :namespace  => "ManageIQ/System",
      :class      => "Request",
      :instance   => "order_ansible_playbook"
    },
    :parameters => {
      :service_template_name  => playbook,
      :hosts                  => host,
      :dialog_credential      => credential
    },
    :requester => { :auto_approve => true }
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

def check_automation_request(request_id)
  url = URI.encode(API_URI + "/automation_requests/#{request_id}")

  rest_return = RestClient::Request.execute(
    method:     :get,
    url:        url,
    :headers    => {
      :accept => :json,
      'x-auth-token' => @auth_token
    },
    verify_ssl: false)
  result = JSON.parse(rest_return)

  result['request_state']
end

require 'rest-client'

API_URI     = 'https://localhost/api'
USER        = 'admin'
PASSWORD    = 'smartvm'
@auth_token = get_auth

prov = $evm.root["miq_provision"]
host = prov.vm.ipaddresses[1]

install_app = prov.options[:ws_values][:install_app]

exit MIQ_OK if install_app.nil? || install_app == 'none'

# Default VMware machine credentials
name = "tbc"

credential = $evm.vmdb('ManageIQ_Providers_AutomationManager_Authentication').find_by(:name => name).id
raise 'Credentials not found' if credential.nil?

request_id = exec_automation_request(install_app, host, credential)