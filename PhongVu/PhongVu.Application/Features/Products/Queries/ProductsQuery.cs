using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Products.Queries
{
    public record ProductsQueryRequest : IRequest<IEnumerable<Product>>
    {
    }

    public class ProductsQueryHandler : BaseService, IRequestHandler<ProductsQueryRequest, IEnumerable<Product>>
    {
        public ProductsQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<Product>> Handle(ProductsQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.ProductRepository.GetAll());
        }
    }
}
