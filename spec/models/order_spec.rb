require 'rails_helper'

describe Order, type: :model do
  describe "validations" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :address }
    it { should validate_presence_of :city }
    it { should validate_presence_of :state }
    it { should validate_presence_of :zip }
    it { should validate_presence_of :status }
  end

  describe "relationships" do
    it {should belong_to :user}
    it {should have_many :item_orders}
    it {should have_many(:items).through(:item_orders)}
  end

  describe "status" do
    it "can be pending" do
      order = create(:order, status: 0)
      expect(order.status).to eq("pending")
      expect(order.pending?).to be_truthy
    end

    it "can be packaged" do
      order = create(:order, status: 1)
      expect(order.status).to eq("packaged")
      expect(order.packaged?).to be_truthy
    end

    it "can be shipped" do
      order = create(:order, status: 2)
      expect(order.status).to eq("shipped")
      expect(order.shipped?).to be_truthy
    end

    it "can be cancelled" do
      order = create(:order, status: 3)
      expect(order.status).to eq("cancelled")
      expect(order.cancelled?).to be_truthy
    end
  end

  describe 'instance methods' do
    before :each do
      @meg = Merchant.create(name: "Meg's Bike Shop", address: '123 Bike Rd.', city: 'Denver', state: 'CO', zip: 80203)
      @brian = Merchant.create(name: "Brian's Dog Shop", address: '125 Doggo St.', city: 'Denver', state: 'CO', zip: 80210)

      @tire = @meg.items.create(name: "Gatorskins", description: "They'll never pop!", price: 100, image: "https://www.rei.com/media/4e1f5b05-27ef-4267-bb9a-14e35935f218?size=784x588", inventory: 12)
      @pull_toy = @brian.items.create(name: "Pull Toy", description: "Great pull toy!", price: 10, image: "http://lovencaretoys.com/image/cache/dog/tug-toy-dog-pull-9010_2-800x800.jpg", inventory: 32)

      @customer = create(:user)
      @order_1 = @customer.orders.create!(name: 'Meg', address: '123 Stang Ave', city: 'Hershey', state: 'PA', zip: 17033)

      @order_1.item_orders.create!(item: @tire, price: @tire.price, quantity: 2)
      @fullfilled_pull_toys = @order_1.item_orders.create!(item: @pull_toy, price: @pull_toy.price, quantity: 3)
    end

    it 'grandtotal' do
      expect(@order_1.grandtotal).to eq(230)
    end

    it 'merchant_items' do
      expect(@order_1.merchant_items(@meg).first).to eq(@order_1.item_orders.first)
    end

    it 'cancel when no item_orders fulfilled' do
      @order_1.cancel
      expect(@order_1.status).to eq("cancelled")
    end

    it 'cancel when some item_orders fulfilled' do
      expect(@pull_toy.inventory).to eq(32)

      @fullfilled_pull_toys.fulfill
      expect(@pull_toy.inventory).to eq(29)

      @order_1.cancel
      expect(@order_1.status).to eq("cancelled")
      expect(@fullfilled_pull_toys.status).to eq("unfulfilled")
      expect(@pull_toy.inventory).to eq(32)
    end

    it "only package when all item orders fulfilled" do
      expect(@order_1.item_orders.size).to eq(2)
      expect(@order_1.status).to eq("pending")

      @order_1.item_orders.first.fulfill
      expect(@order_1.item_orders.all?(&:fulfilled?)).to be_falsey
      expect(@order_1.can_pack?).to be_falsey

      @order_1.pack
      expect(@order_1.status).to eq("pending")

      @order_1.item_orders.last.fulfill
      expect(@order_1.item_orders.all?(&:fulfilled?)).to be_truthy
      expect(@order_1.can_pack?).to be_truthy

      @order_1.pack
      expect(@order_1.status).to eq("packaged")
    end
  end
end
