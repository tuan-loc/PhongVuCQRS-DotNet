using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Categories.Queries
{
    public record CategoryQueryRequest(short id) : IRequest<Category>;

    public class CategoryQueryHandler : BaseService, IRequestHandler<CategoryQueryRequest, Category>
    {
        public CategoryQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<Category> Handle(CategoryQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.CategoryRepository.GetById(request.id));
        }
    }
}
