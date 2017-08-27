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
  ledvalue = 0x02
  if existance then ledvalue = 0x00 end
  s, indata = fa.pio(0x03, ledvalue)
  return bit32.band(indata, 0x10) == 0
end

show_welcome()

for i=1,2 do
  sleep(2000)
  show_booting()
end
sleep(2000)

show_booted()

while true do
  sleep(100)

  if is_pushed(existance) then
    existance = not existance
    show_registered()
  end
end
