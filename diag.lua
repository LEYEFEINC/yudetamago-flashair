function led_impl(led, ms)
  fa.pio(0x03, led)
  sleep(ms)
  fa.pio(0x03, 0x00)
  sleep(ms)
end

function data()
  led_impl(0x02, 100)
  led_impl(0x02, 100)
end

function error()
  led_impl(0x01, 100)
  led_impl(0x01, 100)
end

function is_pushed(existance)
  ledvalue = 0x02
  if existance then ledvalue = 0x00 end
  s, indata = fa.pio(0x03, ledvalue)
  return bit32.band(indata, 0x10) == 0
end

data()
error()

existance = true
while true do
  sleep(100)
  if is_pushed(existance) then
    data()
    error()
  end
end
