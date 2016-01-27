# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

unless Rails.env == "production"
  violation = Violation.where({
    :guid => "123456789",
    :description => "A FAKE VIOLATION"
  }).first_or_create!

  puts violation.inspect

  citation = Citation.where({
    :guid => "987654321",
    :violation_id => violation.id,
    :location => "123 FAKE STREET",
    :payable => 1
  }).first_or_create!

  puts citation.inspect

  appointment = Appointment.where({
    :citation_id => citation.id,
    :defendant_full_name => "FAKE PERSON",
    :room => "3B",
    :date => "20-JAN-15",
    :time => "03:00:00 PM"
  }).first_or_create!

  puts appointment.inspect
end

puts "SEEDED"
