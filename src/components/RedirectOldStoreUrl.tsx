import { Navigate, useParams } from 'react-router-dom';

/**
 * Redirects old /s/:slug URLs to new /:slug format
 */
const RedirectOldStoreUrl = () => {
  const { slug } = useParams<{ slug: string }>();
  return <Navigate to={`/${slug}`} replace />;
};

export default RedirectOldStoreUrl;
