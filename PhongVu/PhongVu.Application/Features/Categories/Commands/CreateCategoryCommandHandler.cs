using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Application.Dto.CategoryDto;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Categories.Commands
{
    public record CreateCategoryCommandRequest(CategoryDto categoryDto) : IRequest<int>;

    public class CreateCategoryCommandHandler : BaseService, IRequestHandler<CreateCategoryCommandRequest, int>
    {
        public CreateCategoryCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(CreateCategoryCommandRequest request, CancellationToken cancellationToken)
        {
            var category = mapper.Map<Category>(request.categoryDto);
            return Task.FromResult(provider.CategoryRepository.Add(category));
        }

    }
}
