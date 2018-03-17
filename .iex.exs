alias Gringotts.CreditCard
alias Gringotts.Address

#[:street1, :street2, :city, :region, :country, :postal_code, :phone]

add= %Address{
    street1: "OBH",
    street2: "AIT",
    city: "PUNE",
    region: "Maharashtra", 
    country: "IN",
    postal_code: "411015",
    phone: "8007810916"
}

card = %CreditCard{
    
    number: "4200000000000000",
    month: 12,
    year: 2099,
    first_name: "Harry",
    last_name: " Potter",
    verification_code:  "123",
    brand: "VISA"
    
    
    
    

}

customer = %{"description": "Harry",
             "email": "masterofdeath@ministryofmagic.gov",
             "ip_address": "1.1.1.5", 
            }

amount = Money.new(:AUD, 1000)
auth = [config: %{apiKey: "c4nxgznanW4XZUaEQhxS6g", pass: ""}]
opts = auth ++ [customer: customer] ++add
header = [{"Authorization", "Basic YzRueGd6bmFuVzRYWlVhRVFoeFM2Zzo="}]