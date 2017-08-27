dofile("bootscript_config.lua")

NIFTY_RETRY_TIMES = 3

function led_impl(led, ms)
  fa.pio(0x03, led)
  sleep(ms)
  fa.pio(0x03, 0x00)
  sleep(ms)
end

function show_welcome()
  led_impl(0x03, 500)
end

function show_booting()
  led_impl(0x02, 500)
end

function show_booted()
  led_impl(0x02, 100)
  led_impl(0x02, 100)
  led_impl(0x02, 100)
  led_impl(0x02, 100)
end

function show_registered()
  led_impl(0x02, 500)
  led_impl(0x02, 500)
end

function show_error()
  while true do
    led_impl(0x01, 500)
  end
end

function is_pushed(existance)
  local ledvalue = 0x02
  if existance then ledvalue = 0x00 end
  local s, indata = fa.pio(0x03, ledvalue)
  return bit32.band(indata, 0x10) == 0
end

function set_existance_impl(existance)
  local command = "{\"existing\":\""..existance.."\"}"
  local b, c, h = fa.request{
    url     = "https://mb.api.cloud.nifty.com/2013-09-01/classes/ToggleStocker/"..object_id,
    method  = "PUT",
    headers = {
      ["X-NCMB-Application-Key"] = application_key,
      ["X-NCMB-Timestamp"] = timestamp,
      ["X-NCMB-Signature"] = set_existance_signature,
      ["Content-Type"]     = "application/json",
      ["Content-Length"]   = tostring(string.len(command))},
    body    = command}
  return c
end

function set_existance(existance)
  local i
  for i=1,NIFTY_RETRY_TIMES do
    local c = set_existance_impl(existance)
    if c == 200 then return end
  end
  show_error()
end

function get_existance_impl()
  local b, c, h = fa.request{
    url     = "https://mb.api.cloud.nifty.com/2013-09-01/classes/ToggleStocker?where=%7B%22objectId%22%3A%22"..object_id.."%22%7D",
    method  = "GET",
    headers = {
      ["X-NCMB-Application-Key"] = application_key,
      ["X-NCMB-Timestamp"] = timestamp,
      ["X-NCMB-Signature"] = get_existance_signature,
      ["Content-Type"]     = "application/json"}
    }
  local a, b, existing = string.find(b, "existing\":\"(.)\"")
  return existing
end

function get_existance()
  local i
  for i=1,NIFTY_RETRY_TIMES do
    local  existing = get_existance_impl()
    if     existing == "1" then return true
    elseif existing == "0" then return false
    end
  end
  show_error()
end

function push_notification_impl(title, message)
  local command = "{\"immediateDeliveryFlag\":true,\"target\":[\"android\"],\"message\":\"\",\"title\":\"\",\"userSettingValue\":{\"objectId\":[\""..object_id.."\"]}}"
  local b, c, h = fa.request{
    url     = "https://mb.api.cloud.nifty.com/2013-09-01/push",
    method  = "POST",
    headers = {
      ["X-NCMB-Application-Key"] = application_key,
      ["X-NCMB-Timestamp"] = timestamp,
      ["X-NCMB-Signature"] = push_notification_signature,
      ["Content-Type"]     = "application/json",
      ["Content-Length"]   = tostring(string.len(command))},
    body    = command}
  return c
end

function push_notification(title, message)
  local i
  for i=1,NIFTY_RETRY_TIMES do
    local c = push_notification_impl(title, message)
    if c == 201 then return end
  end
  show_error()
end


show_welcome()

-- wait for connecting by wifi
for i=1,60 do
  if (fa.WlanLink() == 1) then break end
  sleep(2000)
  show_booting()
  if i == 60 then
    show_error()
  end
end
sleep(2000)

show_booted()

while true do
  existance = get_existance()
  -- invoke get_existance() per 5min
  -- (100ms x 3000 = 5min)
  -- for i=1,3000 do
  for i=1,3000 do
    sleep(100)

    if is_pushed(existance) then
      existance = not existance
      if existance then
        set_existance("1")
        push_notification("Full", "existance state")
      else
        set_existance("0")
        push_notification("Near empty", "not existance state")
      end
      show_registered()
    end
  end
end
