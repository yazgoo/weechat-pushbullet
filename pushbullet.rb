require 'presbeus'
# callback for data received in input
def buffer_input_cb(data, buffer, input_data)
  device = Weechat.buffer_get_string(b, "localvar_device")
  Presbeus.new.send_sms device, data, input_data
  Weechat.print(Weechat.current_buffer(), ">\t#{input_data}")
  return Weechat::WEECHAT_RC_OK
end

# callback called when buffer is closed
def buffer_close_cb(data, buffer)
  return Weechat::WEECHAT_RC_OK
end

def reload_thread(data, b, args)
    begin
      address = Weechat.buffer_get_string(b, "localvar_address")
      device = Weechat.buffer_get_string(b, "localvar_device")
      Presbeus.new.thread(device, address).reverse.each do |c|
        Weechat.print(b, "#{c["direction"] == "outgoing" ? ">" : "<"}\t#{c["body"]}")
      end
    rescue => e
      Weechat.print(b, "#{e}")
    end
  return Weechat::WEECHAT_RC_OK
end

def load_device(data, b, device)
  Weechat.print('', "loading device #{device}")
  Presbeus.new.threads(device).each do |address, name|
    Weechat.print('', "creating buffer for #{device} #{address} #{name}")
    b = Weechat.buffer_new(name, 'buffer_input_cb', name, 'buffer_close_cb', name)
    Weechat.buffer_set(b, "localvar_set_address", address)
    Weechat.buffer_set(b, "localvar_set_device", device)
    reload_thread(nil, b, nil)
  end
  return Weechat::WEECHAT_RC_OK
end

def weechat_init
  Weechat.register('pushbullet',
                   'PushBullet', '1.0', 'GPL3', 'Pushbullet', '', '')
  Weechat.hook_command("pb_r", "reload pushbullet tread", "", "", "", "reload_thread", "")
  Weechat.hook_command("pb_d", "load device", "", "", "", "load_device", "")
  Weechat.print('', "devices:")
  Presbeus.new.devices.each { |d|  Weechat.print('', d.join(": ")) }
  Weechat.print('', "launch '/pb_d <device_id>' to load device")
  return Weechat::WEECHAT_RC_OK
end
