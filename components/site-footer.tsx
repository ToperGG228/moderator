export function SiteFooter() {
  return (
    <footer className="border-t border-orange-100 bg-white py-8 text-sm text-slate-600">
      <div className="container-section flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="font-semibold text-brand">Бабушкины вкусности и рукоделие</p>
          <p>Домашние деликатесы, выпечка и уютные вязаные изделия.</p>
        </div>
        <div className="flex gap-4">
          <a href="/sitemap.xml" className="hover:text-brand">
            Карта сайта
          </a>
          <a href="/robots.txt" className="hover:text-brand">
            robots.txt
          </a>
          <a href="/privacy" className="hover:text-brand">
            Политика
          </a>
        </div>
      </div>
    </footer>
  );
}
