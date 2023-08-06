namespace PhongVu.Domain.Entities
{
    public class Product
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; } = null!;
        public string ImageUrl { get; set; } = null!;
        public string Pattern { get; set; }
        public string Description { get; set; }
        public short Quantity { get; set; }
        public int QuantitySold { get; set; }
        public int UnitPrice { get; set; }
        public int SalePrice
        {
            get
            {
                if(Promotion != null)
                {
                    return UnitPrice * (100 - Promotion.Value) / 100;
                }
                return UnitPrice;
            }
        }
        public int? Promotion { get; set; }
        public string Present { get; set; }
        public short CategoryId { get; set; }
    }
}
