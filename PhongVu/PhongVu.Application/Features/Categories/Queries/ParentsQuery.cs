using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Categories.Queries
{
    public class ParentsQueryRequest : IRequest<IEnumerable<Category>>
    {
    }

    public class ParentsQueryHandler : BaseService, IRequestHandler<ParentsQueryRequest, IEnumerable<Category>>
    {
        public ParentsQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<Category>> Handle(ParentsQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.CategoryRepository.GetParents());
        }
    }
}
