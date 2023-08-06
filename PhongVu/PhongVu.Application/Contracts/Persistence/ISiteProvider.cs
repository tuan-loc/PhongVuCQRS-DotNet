namespace PhongVu.Application.Contracts.Persistence
{
	public interface ISiteProvider
	{
		public ICategoryRepository CategoryRepository { get; }
		public IBannerRepository BannerRepository { get; }
		public IAuthRepository AuthRepository { get; }
		public IMemberRepository MemberRepository { get; }
		public IRoleRepository RoleRepository { get; }
		public IBannerTypeRepository BannerTypeRepository { get; }
		public IProductRepository ProductRepository { get; }
	}
}
