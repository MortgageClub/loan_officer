require "csv"

class Contact
  attr_accessor :agent, :csv

  def initialize
    @agent = Mechanize.new
    @agent.request_headers = {"Content-Type" => "application/json", "Authorization" => "Bearer 6e1s4my4seaxlzhacmwv5ja9tp1798cw"}
    @csv = CSV.open("public/contact_id.csv", "ab")
  end

  def call
    1.upto(17).each do |index|
      response = agent.get "https://api.contactually.com/v2/buckets/bucket_57557537/contacts?page=#{index}"
      data = JSON.load(response.body).first.last
      data.each do |item|
        csv << [item["addresses"].first["street_1"], item["id"]]
      end
    end

    csv.close
  end
end