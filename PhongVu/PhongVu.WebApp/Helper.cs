using System.Text.Json;

namespace PhongVu.WebApp
{
    public static class Helper
    {
        public static T? Get<T>(this ISession session, string key) where T : class
        {
            string? str = session.GetString(key);
            if(str != null)
            {
                return JsonSerializer.Deserialize<T>(str);
            }
            return null;
        }

        public static void Set<T>(this ISession session, string key, T value) where T : class
        {
            session.SetString(key, JsonSerializer.Serialize(value));
        }
    }
}
