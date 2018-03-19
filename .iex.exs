alias Gringotts.CreditCard
alias Gringotts.Address

#[:street1, :street2, :city, :region, :country, :postal_code, :phone]

  
add= [%Address{
    street1: "OBH",
    street2: "AIT",
    city: "PUNE",
    region: "Maharashtra", 
    country: "IN",
    postal_code: "411015",
    phone: "8007810916"
}]

card = %CreditCard{
    
    number: "4200000000000000",
    month: 12,
    year: 2099,
    first_name: "Harry",
    last_name: " Potter",
    verification_code:  "123",
    brand: "VISA"
    
    
    
    

}

customer = [
             email: "roland@pinpayments.com",
             description: "Harry",
             ip_address: "1.1.1.5"
            ]


amount = Money.new(1000, :AUD)
auth = [config: %{apiKey: "c4nxgznanW4XZUaEQhxS6g", pass: ""}]
opts =  customer ++ add


 hiparam=[
      "card[number]": card.number,
      "card[name]": card.first_name <> card.last_name,
      "card[expiry_month]": card.month |> Integer.to_string() |> String.pad_leading(2, "0"),
      "card[expiry_year]": card.year |> Integer.to_string(),
      "card[cvc]": card.verification_code,
      "card[address_line1]": opts[:Address][:street1],
      "card[address_city]": opts[:Address][:city],
      "card[address_country]": opts[:Address][:country],
      "description": "hello",
      "email": "hi@hello.com"
    ]
    payment_id = "ch_JfqXbZp1_cjTVIpumDTZgQ"

 url="https://test-api.pinpayments.com" <> "/1/" <>"charges/" <> payment_id <> "/refunds"
 headers = [{"Content-Type", "application/x-www-form-urlencoded"},{"Authorization", "Basic YzRueGd6bmFuVzRYWlVhRVFoeFM2Zzo="}]