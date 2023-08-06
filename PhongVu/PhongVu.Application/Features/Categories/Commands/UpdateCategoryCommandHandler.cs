using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Categories.Commands
{
    public record UpdateCategoryCommandRequest(Category category) : IRequest<int>;

    public class UpdateCategoryCommandHandler : BaseService, IRequestHandler<UpdateCategoryCommandRequest, int>
    {
        public UpdateCategoryCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(UpdateCategoryCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.CategoryRepository.Edit(request.category));
        }
    }
}
