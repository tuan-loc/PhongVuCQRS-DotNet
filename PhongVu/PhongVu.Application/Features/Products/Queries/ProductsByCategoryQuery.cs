using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Products.Queries
{
    public record ProductsByCategoryQueryRequest(short id) : IRequest<IEnumerable<Product>>
    {
    }

    public class ProductsByCategoryQueryHandler : BaseService, IRequestHandler<ProductsByCategoryQueryRequest, IEnumerable<Product>>
    {
        public ProductsByCategoryQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<Product>> Handle(ProductsByCategoryQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.ProductRepository.GetProductsByCategory(request.id));
        }
    }
}
