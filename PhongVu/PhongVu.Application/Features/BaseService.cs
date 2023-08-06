using AutoMapper;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features
{
	public abstract class BaseService
	{
		protected ISiteProvider provider;
		protected IMapper mapper;
		public BaseService(ISiteProvider provider, IMapper mapper)
		{
			this.provider = provider;
			this.mapper = mapper;

        }
	}
}
