using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Categories.Queries
{
	public class CategoriesQueryRequest : IRequest<IEnumerable<Category>>
	{
	}

	public class CategoriesQueryHandler : BaseService, IRequestHandler<CategoriesQueryRequest, IEnumerable<Category>>
	{
		public CategoriesQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
		{
		}

		public Task<IEnumerable<Category>> Handle(CategoriesQueryRequest request, CancellationToken cancellationToken)
		{
            return Task.FromResult(provider.CategoryRepository.GetAll());
		}
	}
}
