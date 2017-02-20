require "watir"
require "csv"

class LoopNetRefinance
  attr_accessor :browser, :csv, :states, :types, :date_ranges, :header

  def initialize
    @header = [
      "Address", "Date Range", "Primary Property Type 1", "Property Sub-type 1", "LoopNet MPID 1",  "No. Units 1", "No. Stories 1", "Year Built 1", "Ground Floor 1", "Building Improvement Type 1", "Building Code 1", 
      "APN/Parcel ID Property 1", "Census Tract 1", "Building Size 1",  "Lot Size 1", "Lot Number 1", "Zoning 1",
      "APN/Parcel ID Property 2", "Census Tract 2", "Building Size 2",  "Lot Size 2", "Lot Number 2", "Zoning 2", 
      "APN/Parcel ID Property 3", "Census Tract 3", "Building Size 3",  "Lot Size 3", "Lot Number 3", "Zoning 3", 
      "Date 1", "Event 1", "APN/Parcel ID Owner 1", "Owner 1", "Address 1", "Rights 1", "Sale Price 1", "Mortgage Date 1", "Mortgage Details (at time of loan) 1", "Mortgage Deed Type 1", "Lender Name 1", "Lender Address 1", 
      "Date 2", "Event 2", "APN/Parcel ID Owner 2", "Owner 2", "Address 2", "Rights 2", "Sale Price 2", "Mortgage Date 2", "Mortgage Details (at time of loan) 2", "Mortgage Deed Type 2", "Lender Name 2", "Lender Address 2", 
      "Date 3", "Event 3", "APN/Parcel ID Owner 3", "Owner 3", "Address 3", "Rights 3", "Sale Price 3", "Mortgage Date 3", "Mortgage Details (at time of loan) 3", "Mortgage Deed Type 3", "Lender Name 3", "Lender Address 3" 
    ]

    @states = ["Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"]

    @types = ["Multifamily", "Office", "Industrial"]
    # 
    @date_ranges = [["05/01/2017", "05/31/2017"]]
  end

  def call
    states.each do |state|
      @browser = Watir::Browser.new
      @browser.window.maximize
      @csv = CSV.open("public/output_loop_net_refinance_#{state}.csv", "ab")
      @csv << header

      login

      Rails.logger.debug "-----------------------------------start #{state}"
      date_ranges.each do |date_range|
        types.each do |type|
          begin
            search(state, type, date_range[0], date_range[1])
            get_properties(date_range, state)
          rescue Exception => e
            ap e
          end
        end 
      end
      Rails.logger.debug "-----------------------------------end #{state}"

      close_browser
      csv.close
      sleep(30)
    end
  end

  def call_single(state, type, date_range)
    @browser = Watir::Browser.new
    @browser.window.maximize
    @csv = CSV.open("public/output_loop_net_refinance_#{state}.csv", "ab")
    @csv << header

    login 
    begin
      search(state, type, date_range[0], date_range[1])
      get_properties(date_range, state)
    rescue Exception => e
      ap e
    end

    close_browser
    csv.close
  end

  def login
    browser.goto "http://www.loopnet.com/xNet/MainSite/User/customlogin.aspx?LinkCode=31824"
    browser.text_field(id: "ctlLogin_LogonEmail").set "dane.chodos@blacklinelending.com"
    browser.text_field(id: "ctlLogin_LogonPassword").set "Pickman45"
    browser.link(id: "ctlLogin_btnLogon").click
  end

  def search(state, type, date_from, date_to)
    Rails.logger.debug "State: #{state} - Type: #{type} - From: #{date_from} - #{date_to}"

    browser.goto "http://www.loopnet.com/propertyrecords/"
  
    browser.link(class: "typeSelect").click
    browser.link(title: type).click

    browser.text_field(id: "Location").set state

    browser.text_field(id: "mortgageFrom").set date_from
    browser.text_field(id: "owner").click
    browser.text_field(id: "mortgageTo").set date_to
    browser.text_field(id: "owner").click
    
    browser.link(id: "location_search_btn").click
  end

  def get_properties(date_range, state)
    sleep(6)
    if browser.link(class: "searchResultPhoto").exists?
      links = []

      while true do
        links += browser.links(class: "searchResultPhoto").map { |link| link.attribute_value("href") }
        
        next_link = browser.div(id: "pagingbottom").span(class: "caret-right")
        break unless next_link.exists?

        next_link.click
        sleep(10)
      end

      links.each_with_index do |link, index|
        browser.goto link
        sleep(2)
        row = CSV::Row.new(header,[])

        row["Address"] = browser.div(class: "listingProfileDetail").exists? ? browser.div(class: "listingProfileDetail").h1.text : browser.url
        row["Date Range"] = "#{date_range[0]} - #{date_range[1]}"
        Rails.logger.debug "#{index + 1}/#{links.size} #{state}, #{row["Address"]}"

        if browser.link(id: "lnkMenuPropertyDetails").exists?
          browser.link(id: "lnkMenuPropertyDetails").click

          browser.tables(class: "keyValue").each_with_index do |table, index|
            next if index > 2

            table.tbody.trs.each do |tr|
              if tr.th.text == "APN/Parcel ID"
                row["#{tr.th.text} Property #{index + 1}"] = tr.td.text
              else
                row["#{tr.th.text} #{index + 1}"] = tr.td.text
              end
            end
          end
        end
        
        if browser.link(id: "lnkMenuOwnerMortgage").exists?
          browser.link(id: "lnkMenuOwnerMortgage").click

          browser.tables(class: "keyValue").each_with_index do |table, index|
            next if index > 2

            row["Date #{index + 1}"] = table.thead.text
            table.tbody.trs.each do |tr|
              if tr.th.text == "APN/Parcel ID"
                row["#{tr.th.text} Owner #{index + 1}"] = tr.td.text
              else
                row["#{tr.th.text} #{index + 1}"] = tr.td.text
              end
            end
          end
        end

        csv << row
      end
    else
      Rails.logger.debug "No Data Available"
    end
  end

  def close_browser
    browser.goto "http://www.loopnet.com/xNet/MainSite/User/logoff.aspx?LinkCode=850"
    browser.quit
  end
end