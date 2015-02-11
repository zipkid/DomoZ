SimpleCov.start do
  # any custom configs like groups and filters can be here at a central place
  command_name 'MiniTest'
  add_filter "/test/"
  # add_group 'Plugins', 'lib/message_broker/plugins'
  add_group "Long files" do |src_file|
    src_file.lines.count > 100
  end
end
