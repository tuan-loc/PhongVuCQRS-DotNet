using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Products.Queries
{
    public record ProductQueryRequest(int id) : IRequest<Product>;

    public class ProductQueryHandler : BaseService, IRequestHandler<ProductQueryRequest, Product>
    {
        public ProductQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<Product> Handle(ProductQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.ProductRepository.GetById(request.id));
        }
    }
}
