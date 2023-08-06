namespace PhongVu.Application.Contracts.Persistence
{
	public interface IRepository<T, TKey> where T : class
	{
		IEnumerable<T> GetAll();
		T GetById(TKey id);
		int Add(T entity);
		int Delete(TKey id);
		int Edit(T entity);
	}
}
