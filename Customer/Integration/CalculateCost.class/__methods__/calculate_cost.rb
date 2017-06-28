#
# Description: <Method description here>
#

$evm.root.attributes.sort.each { |k, v| $evm.log(:info, "\t Attribute: #{k} = #{v}")}

# exit MIQ_OK unless $evm.root.attributes.has_key?('dialog_template')

cpu_price      = $evm.object['cpu_price']                   # get os price per CPU from the instance
mem_price      = $evm.object['mem_price']                   # get size price per GB from the instance
storage_price  = $evm.object['storage_price']           # get storage price per GB from the instance

if $evm.root.attributes.has_key?('dialog_template')
  # VM bundle

  number_of_vms = $evm.root['dialog_number_of_vms']
  number_of_vms ? number_of_vms = number_of_vms.to_i : (exit MIQ_OK)

  # image_ems_ref = "vm-71"

  image_ems_ref = $evm.root['dialog_template']
  image_ems_ref = image_ems_ref.gsub(/_/,'-')

  image = $evm.vmdb(:VmOrTemplate).find_by(:ems_ref => image_ems_ref)
  # raise 'Image not found' if image.nil?
  exit MIQ_OK if image.nil?

  number_of_sockets = 1
  cores_per_socket  = 2
  cpu_count         = number_of_sockets * cores_per_socket
  mem_size          = 2 # GB
  storage_size      = image.disk_1_size.to_i / (1024 * 1024 * 1024) # GB

  number_of_vms = $evm.root['dialog_number_of_vms'].to_i

else

  case $evm.root['vmdb_object_type']
  when 'service_template'
    # Standard, single catalogue item request...

    service_template = $evm.root['service_template']

    # $evm.log(:info, service_template)
    # $evm.log(:info, service_template.associations)

    # service_template  = $evm.vmdb('service_template')
    resource          = service_template.service_resources.first.resource

    number_of_sockets = resource.options[:number_of_sockets].first.to_i
    cores_per_socket  = resource.options[:cores_per_socket].first.to_i
    cpu_count         = number_of_sockets * cores_per_socket

    mem_size          = resource.options[:vm_memory].first.to_i / 1024 # GB

    storage_size      = resource.vm_template.disk_1_size.to_i / (1024 * 1024 * 1024) # GB

    number_of_vms = 1

  else
    exit MIQ_OK
  end

end

# Calculate the cost for the CPU, memory, and storage
cpu_cost     = cpu_price * cpu_count
mem_cost     = mem_price * mem_size
storage_cost = (storage_price * storage_size)

total_cost = (cpu_cost + mem_cost + storage_cost) * number_of_vms

# Deteremine the total cost and round to two decimal points
total_cost = sprintf("%.2f", total_cost.round(2))

$evm.log(:info, " cpu count: #{cpu_count}       cpu cost = #{cpu_cost}")
$evm.log(:info, " memory GB: #{mem_size}     memory cost = #{mem_cost}")
$evm.log(:info, "storage GB: #{storage_size}     storage = #{storage_cost}")
$evm.log(:info, "total cost = #{total_cost}")

# Set form field to the calculated value
$evm.object['value'] = total_cost

# Set the form field to be read-only so the user cannot change it
$evm.object['read_only'] = true
