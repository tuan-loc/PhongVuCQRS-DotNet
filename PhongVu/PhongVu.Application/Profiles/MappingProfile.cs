using AutoMapper;
using PhongVu.Application.Dto.BannerDto;
using PhongVu.Application.Dto.CategoryDto;
using PhongVu.Application.Dto.RoleDto;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Profiles
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Category, CategoryDto>().ReverseMap();
            CreateMap<Banner, BannerDto>().ReverseMap();
            CreateMap<Role, CreateRoleDto>().ReverseMap();
        }
    }
}
