using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features.Categories.Commands
{
    public record DeleteCategoryCommandRequest(short id) : IRequest<int>;

    public class DeleteCategoryCommandHandler : BaseService, IRequestHandler<DeleteCategoryCommandRequest, int>
    {
        public DeleteCategoryCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(DeleteCategoryCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.CategoryRepository.Delete(request.id));
        }
    }
}
