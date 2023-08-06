using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Persistence
{
	public class SiteProvider : BaseProvider, ISiteProvider
	{
		public SiteProvider(string connectionString) : base(connectionString)
		{
		}

		ICategoryRepository category = null!;

		public ICategoryRepository CategoryRepository => category ??= new CategoryRepository(Connection);
		IBannerRepository banner = null!;
		public IBannerRepository BannerRepository => banner ??= new BannerRepository(Connection);
        IAuthRepository auth = null!;
        public IAuthRepository AuthRepository => auth ??= new AuthRepository(Connection);
        IMemberRepository member = null!;
        public IMemberRepository MemberRepository => member ??= new MemberRepository(Connection);
        IRoleRepository role = null!;
        public IRoleRepository RoleRepository => role ??= new RoleRepository(Connection);
		IBannerTypeRepository bannerType = null!;
		public IBannerTypeRepository BannerTypeRepository => bannerType ??= new BannerTypeRepository(Connection);
        IProductRepository product = null!;
        public IProductRepository ProductRepository => product ??= new ProductRepository(Connection);
    }
}
