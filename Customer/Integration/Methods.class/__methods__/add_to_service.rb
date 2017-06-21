#
# Description: <Method description here>
#

#miq_request = $evm.root['miq_request']
prov = $evm.root["miq_provision"]

unless $evm.root["service_template_provision_task"].nil?
  parent_service_id = prov.options[:ws_values][:service_id]

  parent_service = $evm.vmdb('service').find_by_id(parent_service_id)
  #parent_service = $evm.vmdb('service').find_by(:id => parent_service_id)

  prov.vm.add_to_service(parent_service) unless parent_service.nil?
end
