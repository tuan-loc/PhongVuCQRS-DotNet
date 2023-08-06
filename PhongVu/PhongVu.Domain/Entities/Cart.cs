namespace PhongVu.Domain.Entities
{
    public class Cart
    {
        public int ProductId { get; set; }
        public short Quantity { get; set; }
        public string ImageUrl { get; set; } = null!;
        public string ProductName { get; set; } = null!;
        public int Price { get; set; }
        public int Amount
        {
            get
            {
                return Price * Quantity;
            }
        }
    }
}
