num_per_print = 10_000_000

old_time = Time.now()

counter = 0
loop do
  counter += 1

  if counter % num_per_print == 0
    new_time = Time.now
    puts "counter = #{counter} #{sprintf('%1.3e', num_per_print/(new_time-old_time))} loops/sec"
    old_time = new_time
  end
end
